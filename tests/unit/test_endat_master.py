import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.utils import get_sim_time
from entity_runner import run_entity_test

CLK_PERIOD = 16
FRAME_PERIOD = 1500
TCAL_TIMEOUT = 500
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
    data seen by the master, jitter_ns adds a random +/- jitter to each bit."""

    def __init__(self, dut, bits, position=0, tcal=3, tm_ns=1000, delay_ns=0,
                 jitter_ns=0):
        self.dut = dut
        self.bits = bits
        self.position = position
        self.tcal = tcal
        self.tm_ns = tm_ns
        self.delay_ns = delay_ns
        self.jitter_ns = jitter_ns
        self.random = random.Random(1)
        self.error = False
        self.bad_crc = False
        self.glitch = False
        self.modes = []
        self.dut.endat_dat_i.value = 0

    async def _drive_later(self, value, delay_ns):
        await Timer(delay_ns, 'ns')
        self.dut.endat_dat_i.value = value

    def drive(self, value):
        delay_ns = self.delay_ns + self.random.randint(
            -self.jitter_ns, self.jitter_ns)
        if delay_ns:
            cocotb.start_soon(self._drive_later(value, delay_ns))
        else:
            self.dut.endat_dat_i.value = value

    async def run(self):
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
            for i in range(self.tcal):
                await RisingEdge(sck)
                if self.glitch and i == 0:
                    # One clk_i cycle pulse during tcal, half a clock period
                    # out of phase with the data bits
                    await Timer(CLK_PERIOD * 8 // 2, 'ns')
                    self.drive(1)
                    await Timer(8, 'ns')
                    self.drive(0)
            payload = [int(self.error)] + [
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
    """Reset the master, the clock must be running.  delay_comp=0 selects the
    automatic delay compensation"""
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
    # Encoder disconnected, the master gives up waiting for the start bit
    task.cancel()
    dut.endat_dat_i.value = 0
    await FallingEdge(dut.endat_dat_oe_o)
    await ClockCycles(dut.clk_i, TCAL_TIMEOUT + 10)
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


@cocotb.test(timeout_time=3, timeout_unit='ms')
async def endat_auto_delay_compensation(dut):
    start_clock(dut)
    period_ns = CLK_PERIOD * 8
    # Cable round trips of a fraction and of several clock periods, 0.7 puts
    # the data transitions where sampling after the falling edge would be
    for periods in [0, 0.4, 0.7, 1.5, 2.7, 3.3]:
        delay_ns = round(periods * period_ns / 8) * 8 + 4
        await read_positions(dut, 25, delay_ns=delay_ns)


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_auto_delay_jitter(dut):
    start_clock(dut)
    # Data transitions centred on the point the manual mode samples at,
    # DELAY_COMP+3 cycles after the falling edge, with +/- 1/5 period jitter
    delay_ns = CLK_PERIOD * 8 // 2 + 3 * 8
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, delay_ns=delay_ns, jitter_ns=CLK_PERIOD * 8 // 5)
    task = cocotb.start_soon(slave.run())
    for position in range(1000, 1000 + 20 * 997, 997):
        slave.position = position
        await next_result(dut)
        valid, posn = await next_result(dut)
        assert valid == 1
        assert posn == position
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_delay_measured(dut):
    start_clock(dut)
    for delay_cycles in [2, 6, 12]:
        await setup(dut, 25)
        slave = EndatSlave(dut, 25, position=1234, delay_ns=delay_cycles * 8 + 4)
        task = cocotb.start_soon(slave.run())
        await next_result(dut)
        valid, _ = await next_result(dut)
        assert valid == 1
        assert dut.delay_o.value.to_unsigned() == delay_cycles
        task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_start_glitch_rejected(dut):
    start_clock(dut)
    await setup(dut, 25)
    slave = EndatSlave(dut, 25, position=1234, delay_ns=44)
    slave.glitch = True
    task = cocotb.start_soon(slave.run())
    await next_result(dut)
    valid, posn = await next_result(dut)
    assert valid == 1
    assert posn == 1234
    check_health(dut, HEALTH_OK)
    task.cancel()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_manual_delay_compensation(dut):
    start_clock(dut)
    await read_positions(dut, 25, delay_ns=20, delay_comp=2)


def test_endat_master(build_dir):
    run_entity_test(
        'test_endat_master', 'endat_master',
        ['common/hdl/encoders/endat_master.vhd',
         'common/hdl/encoders/endat_crc.vhd',
         'common/hdl/prescaler.vhd',
         'common/hdl/defines/support.vhd'],
        build_dir,
        parameters={'TCAL_TIMEOUT': TCAL_TIMEOUT})
