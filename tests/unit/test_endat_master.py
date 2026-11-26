import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.utils import get_sim_time
from entity_runner import run_entity_test

CLK_PERIOD = 16
FRAME_PERIOD = 1500
TCAL_TIMEOUT = 500
# First low period of the clock (t_ST), in clk_i cycles
START_DELAY = 40
# Encoder send position value
MODE_COMMAND = [0, 0, 0, 1, 1, 1]

HEALTH_OK = 0
HEALTH_TIMEOUT = 2
HEALTH_CRC = 3
HEALTH_ERROR_BIT = 4


def endat_crc(bits):
    """CRC-5 x^5 + x^3 + x + 1, preset to ones, complemented remainder"""
    crc = 0x1F
    for bit in bits:
        inv = bit ^ (crc >> 4)
        crc = ((crc << 1) & 0x1F) ^ (0b01011 if inv else 0)
    return ~crc & 0x1F


class EndatSlave:
    """EnDat encoder model answering the position read mode commands.
    Data is changed on rising edges of the clock and the mode command is read
    on the falling edges. delay_ns models the cable round trip, it delays the
    data seen by the master, including its own mode bits which are looped
    back onto the data line while it drives it. The error bit F1 is sent at
    the level the master was built to take as an error (its F1_ERROR_VALUE
    generic) when error is set, and at the other level otherwise."""

    def __init__(self, dut, bits, position=0, tcal=3, tm_ns=1000, delay_ns=0):
        self.dut = dut
        self.bits = bits
        self.position = position
        self.tcal = tcal
        self.tm_ns = tm_ns
        self.delay_ns = delay_ns
        self.f1_error_value = int(dut.F1_ERROR_VALUE.value)
        self.error = False
        self.bad_crc = False
        self.modes = []
        self.dut.endat_dat_i.value = 0

    async def _drive_later(self, value):
        await Timer(self.delay_ns, 'ns')
        self.dut.endat_dat_i.value = value

    def drive(self, value):
        if self.delay_ns:
            cocotb.start_soon(self._drive_later(value))
        else:
            self.dut.endat_dat_i.value = value

    async def loopback(self):
        """The master sees its own mode bits on the data line, after the
        cable delay, until the encoder takes the line over. The master
        updates its outputs on rising edges of clk_i, so they are checked on
        the falling edges"""
        line = 0
        while True:
            await FallingEdge(self.dut.clk_i)
            if self.dut.endat_dat_oe_o.value == 1:
                value = int(self.dut.endat_dat_o.value)
            else:
                value = 0
            if value != line:
                line = value
                self.drive(value)

    async def run(self):
        loopback = cocotb.start_soon(self.loopback())
        try:
            await self._run()
        finally:
            loopback.cancel()

    async def _run(self):
        sck = self.dut.endat_sck_o
        while True:
            await FallingEdge(sck)
            # Two clock periods to latch the position
            await RisingEdge(sck)
            await RisingEdge(sck)
            mode = []
            for _ in range(6):
                await FallingEdge(sck)
                assert self.dut.endat_dat_oe_o.value == 1
                mode.append(int(self.dut.endat_dat_o.value))
            self.modes.append(mode)
            await RisingEdge(sck)
            assert mode == MODE_COMMAND, f'Unexpected mode {mode}'
            for _ in range(self.tcal):
                await RisingEdge(sck)
            f1 = self.f1_error_value if self.error else 1 - self.f1_error_value
            payload = [f1] + [
                (self.position >> i) & 1 for i in range(self.bits)]
            crc = endat_crc(payload) ^ (1 if self.bad_crc else 0)
            frame = [1] + payload + [(crc >> i) & 1 for i in range(4, -1, -1)]
            for bit in frame:
                self.drive(bit)
                await RisingEdge(sck)
            # Clock stopped, hold the line high for the recovery time
            self.drive(1)
            await Timer(self.tm_ns, 'ns')
            self.drive(0)


def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())


async def setup(dut, bits, delay_comp=0):
    """Reset the master, the clock must be running"""
    dut.reset_i.value = 1
    dut.BITS.value = bits
    dut.CLK_PERIOD.value = CLK_PERIOD
    dut.FRAME_PERIOD.value = FRAME_PERIOD
    dut.DELAY_COMP.value = delay_comp
    dut.endat_dat_i.value = 0
    await ClockCycles(dut.clk_i, 4)
    dut.reset_i.value = 0


async def next_result(dut):
    """Wait for the end of the next frame and return (posn_valid, posn)"""
    await FallingEdge(dut.endat_dat_oe_o)
    # The frame is over once the clock stays high for longer than a period
    valid = 0
    high = 0
    while high <= CLK_PERIOD:
        await RisingEdge(dut.clk_i)
        valid |= int(dut.posn_valid_o.value)
        high = high + 1 if dut.endat_sck_o.value == 1 else 0
    return valid, dut.posn_o.value.to_unsigned()


def check_health(dut, health):
    assert dut.health_o.value.to_unsigned() == health
    assert dut.link_up_o.value == (1 if health == HEALTH_OK else 0)


async def read_positions(dut, bits, delay_ns=0, delay_comp=0):
    await setup(dut, bits, delay_comp)
    slave = EndatSlave(dut, bits, delay_ns=delay_ns)
    task = cocotb.start_soon(slave.run())
    mask = (1 << bits) - 1
    for position in [0, 1, 1 << (bits - 1), mask, 0x5A5A5A5A5A5A5A5A & mask]:
        slave.position = position
        # Skip the frame that may have started before the position changed
        await next_result(dut)
        valid, posn = await next_result(dut)
        assert valid == 1
        # Only the 32 LSBs are kept
        assert posn == position & 0xFFFFFFFF
        check_health(dut, HEALTH_OK)
    task.cancel()


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_position_read(dut):
    start_clock(dut)
    for bits in [13, 25, 32, 37, 63]:
        await read_positions(dut, bits)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_oe_only_during_mode(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234)
    task = cocotb.start_soon(slave.run())
    for _ in range(3):
        # The master drives the data line for the 6 mode bits only
        await RisingEdge(dut.endat_dat_oe_o)
        start = get_sim_time('ns')
        await FallingEdge(dut.endat_dat_oe_o)
        assert get_sim_time('ns') - start == 6 * CLK_PERIOD * 8
    assert len(slave.modes) == 3
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_start_delay(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234)
    task = cocotb.start_soon(slave.run())
    for _ in range(2):
        # The clock stays low for START_DELAY after the first falling edge
        # of a frame, all the other low and high periods are half CLK_PERIOD
        await FallingEdge(dut.endat_sck_o)
        start = get_sim_time('ns')
        await RisingEdge(dut.endat_sck_o)
        assert get_sim_time('ns') - start == START_DELAY * 8
        for _ in range(5):
            start = get_sim_time('ns')
            await FallingEdge(dut.endat_sck_o)
            assert get_sim_time('ns') - start == CLK_PERIOD // 2 * 8
            start = get_sim_time('ns')
            await RisingEdge(dut.endat_sck_o)
            assert get_sim_time('ns') - start == CLK_PERIOD // 2 * 8
        valid, posn = await next_result(dut)
        assert valid == 1
        assert posn == 1234
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_crc_error(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234)
    task = cocotb.start_soon(slave.run())
    valid, posn = await next_result(dut)
    assert valid == 1
    check_health(dut, HEALTH_OK)

    slave.bad_crc = True
    slave.position = 4321
    await next_result(dut)
    valid, posn = await next_result(dut)
    assert valid == 0
    assert posn == 1234
    check_health(dut, HEALTH_CRC)
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_error_bit(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234)
    slave.error = True
    task = cocotb.start_soon(slave.run())
    await next_result(dut)
    valid, _ = await next_result(dut)
    assert valid == 0
    check_health(dut, HEALTH_ERROR_BIT)
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_no_start_bit(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234)
    task = cocotb.start_soon(slave.run())
    valid, _ = await next_result(dut)
    assert valid == 1
    check_health(dut, HEALTH_OK)
    # Encoder disconnected, the master gives up waiting for the start bit.
    # The timeout only starts counting once the last mode bit has been
    # sampled, a serial clock period after the data line is released
    task.cancel()
    dut.endat_dat_i.value = 0
    await FallingEdge(dut.endat_dat_oe_o)
    await ClockCycles(dut.clk_i, TCAL_TIMEOUT + CLK_PERIOD + 10)
    assert dut.endat_sck_o.value == 1
    check_health(dut, HEALTH_TIMEOUT)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_no_frames_when_bits_zero(dut):
    start_clock(dut)
    await setup(dut, 0)
    slave = EndatSlave(dut, 0)
    task = cocotb.start_soon(slave.run())
    for _ in range(FRAME_PERIOD * 3):
        await RisingEdge(dut.clk_i)
        assert dut.endat_sck_o.value == 1
        assert dut.endat_dat_oe_o.value == 0
    assert slave.modes == []
    check_health(dut, HEALTH_TIMEOUT)
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_waits_for_recovery(dut):
    start_clock(dut)
    # Recovery time longer than a frame period, frames must wait for the data
    # line to go low and a frame pulse while waiting reports a timeout
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234, tm_ns=FRAME_PERIOD * 8 * 2)
    task = cocotb.start_soon(slave.run())
    valid, _ = await next_result(dut)
    assert valid == 1
    for _ in range(FRAME_PERIOD * 2 - 100):
        await RisingEdge(dut.clk_i)
        if dut.endat_dat_i.value == 1:
            assert dut.endat_sck_o.value == 1
    check_health(dut, HEALTH_TIMEOUT)
    # Once the line goes low frames carry on
    valid, posn = await next_result(dut)
    assert valid == 1
    assert posn == 1234
    check_health(dut, HEALTH_OK)
    task.cancel()


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_delay_compensation(dut):
    start_clock(dut)
    # The master samples DELAY_COMP+3 clk_i cycles after the falling edge,
    # cable round trips that would put a data transition on or after the
    # uncompensated sampling point
    for delay_ns, delay_comp in [(20, 2), (88, 4), (150, 6)]:
        await read_positions(dut, 25, delay_ns=delay_ns, delay_comp=delay_comp)


# The level of the error bit F1 that means an error. Heidenhain encoders
# transmit F1 low active, other encoders may use the opposite convention.
@pytest.mark.parametrize('f1_error_value', ['0', '1'])
def test_endat_master(build_dir, f1_error_value):
    run_entity_test(
        'test_endat_master', 'endat_master',
        ['common/hdl/encoders/endat_master.vhd',
         'common/hdl/encoders/endat_crc.vhd',
         'common/hdl/prescaler.vhd',
         'common/hdl/defines/support.vhd'],
        build_dir,
        parameters={'TCAL_TIMEOUT': TCAL_TIMEOUT, 'START_DELAY': START_DELAY,
                    'F1_ERROR_VALUE': f"'{f1_error_value}'"})
