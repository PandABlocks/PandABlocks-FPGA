import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from entity_runner import run_entity_test

# EnDat clock period in ns, clk_i is 8ns
PERIOD = 128
TIMEOUT = 4000
# Encoder send position value
MODE_COMMAND = [0, 0, 0, 1, 1, 1]
# Encoder receive parameter, the master keeps driving the line afterwards
MODE_OTHER = [0, 1, 1, 1, 0, 0]

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


class EndatBus:
    """Model of an EnDat master and encoder driving the clock and data lines
    the sniffer listens to. The clock idles high, data changes after the
    rising edges and is read on the falling edges. delay_ns delays the data
    with respect to the clock, as seen at the master end of the cable.
    The error bit F1 is sent at the level the sniffer was built to take as
    an error (its F1_ERROR_VALUE generic) when error is set, and at the
    other level otherwise."""

    def __init__(self, dut, bits, position=0, tcal=3, tm_ns=1000,
                 gap_ns=3000, delay_ns=0):
        self.dut = dut
        self.bits = bits
        self.position = position
        self.tcal = tcal
        self.tm_ns = tm_ns
        self.gap_ns = gap_ns
        self.delay_ns = delay_ns
        self.f1_error_value = int(dut.F1_ERROR_VALUE.value)
        self.error = False
        self.bad_crc = False
        self.dut.endat_sck_i.value = 1
        self.dut.endat_dat_i.value = 0
        self.valids = 0
        cocotb.start_soon(self._count_valids())

    async def _count_valids(self):
        while True:
            await RisingEdge(self.dut.clk_i)
            if self.dut.posn_valid_o.value == 1:
                self.valids += 1

    async def _drive_later(self, value):
        await Timer(self.delay_ns, 'ns')
        self.dut.endat_dat_i.value = value

    def drive(self, value):
        if self.delay_ns:
            cocotb.start_soon(self._drive_later(value))
        else:
            self.dut.endat_dat_i.value = value

    async def clocks(self, values):
        """One clock period per value, the value is driven on the data line
        after the rising edge. The clock is left high."""
        for value in values:
            self.dut.endat_sck_i.value = 0
            await Timer(PERIOD // 2, 'ns')
            self.dut.endat_sck_i.value = 1
            self.drive(value)
            await Timer(PERIOD // 2, 'ns')

    def _request(self, mode):
        # One clock to latch, then the six mode bits from the second rising
        # edge, then the master releases the line
        return [0] + mode + [0]

    async def position_frame(self):
        """A complete position request answered by the encoder"""
        f1 = self.f1_error_value if self.error else 1 - self.f1_error_value
        payload = [f1] + [
            (self.position >> i) & 1 for i in range(self.bits)]
        crc = endat_crc(payload) ^ (1 if self.bad_crc else 0)
        answer = [1] + payload + [(crc >> i) & 1 for i in range(4, -1, -1)]
        # One more clock to read the last CRC bit, then the encoder holds the
        # line high for the recovery time
        await self.clocks(self._request(MODE_COMMAND) + [0] * self.tcal +
                          answer + [1])
        await Timer(self.tm_ns, 'ns')
        self.drive(0)
        await Timer(self.gap_ns, 'ns')

    async def other_frame(self, mode=MODE_OTHER, data=None):
        """A frame with another mode command, the master carries on driving
        data bits, some of them high"""
        if data is None:
            data = [(i * 7) % 3 == 0 for i in range(24)]
        await self.clocks(self._request(mode) + [int(d) for d in data] + [0])
        await Timer(self.gap_ns, 'ns')

    async def unanswered_frame(self):
        """A position request the encoder does not answer, the master gives
        up and stops the clock"""
        await self.clocks(self._request(MODE_COMMAND) + [0] * 8)
        await Timer(self.gap_ns, 'ns')


def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())


async def setup(dut, bits):
    """Reset the sniffer, the clock must be running"""
    dut.reset_i.value = 1
    dut.BITS.value = bits
    dut.endat_sck_i.value = 1
    dut.endat_dat_i.value = 0
    await ClockCycles(dut.clk_i, 4)
    dut.reset_i.value = 0


def check_health(dut, health):
    assert dut.health_o.value.to_unsigned() == health
    assert dut.link_up_o.value == (1 if health == HEALTH_OK else 0)


async def read_positions(dut, bits, delay_ns=0):
    await setup(dut, bits)
    bus = EndatBus(dut, bits, delay_ns=delay_ns)
    mask = (1 << bits) - 1
    for position in [0, 1, 1 << (bits - 1), mask, 0x5A5A5A5A5A5A5A5A & mask]:
        bus.position = position
        valids = bus.valids
        await bus.position_frame()
        assert bus.valids == valids + 1
        # Only the 32 LSBs are kept
        assert dut.posn_o.value.to_unsigned() == position & 0xFFFFFFFF
        check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_position_read(dut):
    start_clock(dut)
    for bits in [13, 25, 32, 37, 63]:
        await read_positions(dut, bits)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_data_delayed(dut):
    start_clock(dut)
    # Data returning late from the encoder, within half a clock period
    await read_positions(dut, 25, delay_ns=40)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_other_commands_skipped(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    await bus.position_frame()
    assert bus.valids == 1
    check_health(dut, HEALTH_OK)
    # Frames with other mode commands leave the position and health alone,
    # whatever the master sends afterwards, and the next position frame is
    # decoded
    last = 1234
    for data in [[0] * 24, [1] * 24, [i % 2 for i in range(24)], None]:
        bus.position = 5555 - last
        valids = bus.valids
        await bus.other_frame(data=data)
        assert bus.valids == valids
        assert dut.posn_o.value.to_unsigned() == last
        check_health(dut, HEALTH_OK)
        await bus.position_frame()
        assert bus.valids == valids + 1
        assert dut.posn_o.value.to_unsigned() == bus.position
        check_health(dut, HEALTH_OK)
        last = bus.position


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_crc_error(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    await bus.position_frame()
    assert bus.valids == 1
    check_health(dut, HEALTH_OK)
    bus.bad_crc = True
    bus.position = 4321
    await bus.position_frame()
    assert bus.valids == 1
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_CRC)
    bus.bad_crc = False
    await bus.position_frame()
    assert bus.valids == 2
    assert dut.posn_o.value.to_unsigned() == 4321
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_error_bit(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    bus.error = True
    await bus.position_frame()
    assert bus.valids == 0
    assert dut.posn_o.value.to_unsigned() == 0
    check_health(dut, HEALTH_ERROR_BIT)
    # The error clears and the position is read again
    bus.error = False
    await bus.position_frame()
    assert bus.valids == 1
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_no_frames_timeout(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    await bus.position_frame()
    check_health(dut, HEALTH_OK)
    # The master stops polling
    await ClockCycles(dut.clk_i, TIMEOUT + 10)
    check_health(dut, HEALTH_TIMEOUT)
    await bus.position_frame()
    assert bus.valids == 2
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_frame_straddling_timeout(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    await bus.position_frame()
    check_health(dut, HEALTH_OK)
    # The master polls slowly, the next frame starts shortly before TIMEOUT
    # expires and is still in progress when it does. position_frame returns
    # the recovery time and the gap after the result, and the frame itself
    # lasts about 45 clock periods
    await Timer(TIMEOUT * 8 - bus.tm_ns - bus.gap_ns - PERIOD * 15, 'ns')
    bus.position = 5678
    await bus.position_frame()
    # The frame is left to complete rather than aborted at the timeout
    assert bus.valids == 2
    assert dut.posn_o.value.to_unsigned() == 5678
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_unanswered_frame(dut):
    start_clock(dut)
    await setup(dut, 25)
    bus = EndatBus(dut, 25, position=1234)
    await bus.position_frame()
    check_health(dut, HEALTH_OK)
    # The encoder does not answer and the master stops the clock, this is
    # reported as soon as the clock stops rather than at the timeout
    await bus.unanswered_frame()
    assert bus.valids == 1
    check_health(dut, HEALTH_TIMEOUT)
    await bus.position_frame()
    assert bus.valids == 2
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_no_capture_when_bits_zero(dut):
    start_clock(dut)
    await setup(dut, 0)
    bus = EndatBus(dut, 25, position=1234)
    for _ in range(3):
        await bus.position_frame()
    assert bus.valids == 0
    assert dut.posn_o.value.to_unsigned() == 0
    check_health(dut, HEALTH_TIMEOUT)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_resync_mid_frame(dut):
    start_clock(dut)
    # Hold the sniffer in reset until the middle of a frame, the position
    # bits here happen to contain the mode command pattern
    dut.reset_i.value = 1
    dut.BITS.value = 25
    bus = EndatBus(dut, 25, position=0b000111000111000111000111)
    frame = cocotb.start_soon(bus.position_frame())
    await Timer(PERIOD * 20, 'ns')
    dut.reset_i.value = 0
    await frame
    # Whatever came out of the partial frame, the next one is decoded
    bus.position = 1234
    valids = bus.valids
    await bus.position_frame()
    assert bus.valids == valids + 1
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_OK)


# The level of the error bit F1 that means an error. Heidenhain encoders
# transmit F1 low active, other encoders may use the opposite convention.
@pytest.mark.parametrize('f1_error_value', ['0', '1'])
def test_endat_sniffer(build_dir, f1_error_value):
    run_entity_test(
        'test_endat_sniffer', 'endat_sniffer',
        ['common/hdl/encoders/endat_sniffer.vhd',
         'common/hdl/encoders/endat_crc.vhd',
         'common/hdl/defines/support.vhd'],
        build_dir,
        parameters={'TIMEOUT': TIMEOUT,
                    'F1_ERROR_VALUE': f"'{f1_error_value}'"})
