import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
from entity_runner import run_entity_test

# EnDat clock period in ns, clk_i is 8ns
PERIOD = 128
# Sampling point after the falling edge of the clock
SAMPLE_NS = 24
TCAL_CLOCKS = 2
RECOVERY = 100
# Encoder send position value
MODE_COMMAND = [0, 0, 0, 1, 1, 1]
# Encoder receive parameter
MODE_OTHER = [0, 1, 1, 1, 0, 0]

HEALTH_OK = 0
HEALTH_TIMEOUT = 2


def endat_crc(bits):
    """CRC-5 x^5 + x^3 + x + 1, preset to ones, complemented remainder"""
    crc = 0x1F
    for bit in bits:
        inv = bit ^ (crc >> 4)
        crc = ((crc << 1) & 0x1F) ^ (0b01011 if inv else 0)
    return ~crc & 0x1F


class EndatMaster:
    """Model of an EnDat master driving the clock and the mode bits and
    reading the slave's answer. The clock idles high, the master drives its
    data after the rising edges and samples the slave's data after the
    falling edges."""

    def __init__(self, dut, bits, gap_ns=1000):
        self.dut = dut
        self.bits = bits
        self.gap_ns = gap_ns
        self.dut.endat_sck_i.value = 1
        self.dut.endat_dat_i.value = 0

    async def clock(self, value=None):
        """One clock period. value is driven on the data line after the
        rising edge. Returns the slave's data and output enable sampled after
        the falling edge."""
        self.dut.endat_sck_i.value = 0
        await Timer(SAMPLE_NS, 'ns')
        sample = (int(self.dut.endat_dat_o.value),
                  int(self.dut.endat_dat_oe_o.value))
        await Timer(PERIOD // 2 - SAMPLE_NS, 'ns')
        self.dut.endat_sck_i.value = 1
        if value is not None:
            self.dut.endat_dat_i.value = value
        await Timer(PERIOD // 2, 'ns')
        return sample

    async def request(self, mode):
        """One clock to latch, the six mode bits from the second rising edge,
        then the master releases the line. Returns the output enables seen
        while the master owns the line."""
        oes = []
        for value in [None] + mode + [0]:
            _, oe = await self.clock(value)
            oes.append(oe)
        return oes

    async def read_position(self, tcal_max=8):
        """A complete position request, returns a dict describing the
        answer"""
        result = {'oe_request': await self.request(MODE_COMMAND)}
        # The slave holds the line low, then sends the start bit
        tcal = 0
        while True:
            dat, oe = await self.clock()
            assert oe == 1, 'Slave is not driving the line after the request'
            if dat == 1:
                break
            tcal += 1
            assert tcal <= tcal_max, 'No start bit'
        result['tcal'] = tcal
        bits = [(await self.clock())[0] for _ in range(1 + self.bits + 5)]
        result['error'] = bits[0]
        posn_bits = bits[1:1 + self.bits]
        result['posn'] = sum(bit << i for i, bit in enumerate(posn_bits))
        crc_bits = bits[1 + self.bits:]
        result['crc'] = sum(bit << (4 - i) for i, bit in enumerate(crc_bits))
        result['crc_ok'] = result['crc'] == endat_crc(bits[:1 + self.bits])
        return result

    async def other_frame(self, mode=MODE_OTHER, data=None):
        """A frame with another mode command, the master carries on driving
        data bits. Returns the output enables seen during the frame."""
        if data is None:
            data = [(i * 7) % 3 == 0 for i in range(24)]
        oes = await self.request(mode)
        for value in [int(d) for d in data] + [0]:
            _, oe = await self.clock(value)
            oes.append(oe)
        await Timer(self.gap_ns, 'ns')
        return oes

    async def recovery(self):
        """After the last CRC bit the slave holds the line high for the
        recovery time and then releases it. Returns (high, released)."""
        await ClockCycles(self.dut.clk_i, 8)
        high = (int(self.dut.endat_dat_o.value),
                int(self.dut.endat_dat_oe_o.value)) == (1, 1)
        await ClockCycles(self.dut.clk_i, RECOVERY + 8)
        released = (int(self.dut.endat_dat_o.value),
                    int(self.dut.endat_dat_oe_o.value)) == (0, 0)
        await Timer(self.gap_ns, 'ns')
        return high, released


def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())


async def setup(dut, bits, position=0, error=0):
    """Reset the slave, the clock must be running"""
    dut.reset_i.value = 1
    dut.BITS.value = bits
    dut.GENERATOR_ERROR.value = error
    dut.posn_i.value = position
    dut.endat_sck_i.value = 1
    dut.endat_dat_i.value = 0
    await ClockCycles(dut.clk_i, 4)
    dut.reset_i.value = 0


def check_health(dut, health):
    assert dut.health_o.value.to_unsigned() == health


def check_answer(result, position, bits, error=0):
    assert all(oe == 0 for oe in result['oe_request']), \
        'Slave drove the line during the request'
    assert result['tcal'] == TCAL_CLOCKS
    assert result['error'] == error
    # Bits above 32 are sent as zero
    assert result['posn'] == position & ((1 << bits) - 1) & 0xFFFFFFFF
    assert result['crc_ok']


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_position_answered(dut):
    start_clock(dut)
    for bits in [13, 25, 32, 37, 63]:
        await setup(dut, bits)
        master = EndatMaster(dut, bits)
        check_health(dut, HEALTH_TIMEOUT)
        mask = (1 << bits) - 1
        for position in [0, 1, 1 << (bits - 1), mask, 0x5A5A5A5A & mask]:
            dut.posn_i.value = position & 0xFFFFFFFF
            result = await master.read_position()
            check_answer(result, position, bits)
            check_health(dut, HEALTH_OK)
            assert await master.recovery() == (True, True)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_error_bit(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234, error=1)
    master = EndatMaster(dut, 25)
    result = await master.read_position()
    check_answer(result, 1234, 25, error=1)
    await master.recovery()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_position_latched_at_frame_start(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234)
    master = EndatMaster(dut, 25)
    # Change the position during the mode command, the answer carries the
    # position at the first falling edge of the clock
    task = cocotb.start_soon(master.read_position())
    await Timer(PERIOD * 3, 'ns')
    dut.posn_i.value = 4321
    result = await task
    check_answer(result, 1234, 25)
    await master.recovery()
    result = await master.read_position()
    check_answer(result, 4321, 25)
    await master.recovery()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_other_commands_ignored(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234)
    master = EndatMaster(dut, 25)
    for data in [[0] * 24, [1] * 24, [i % 2 for i in range(24)], None]:
        oes = await master.other_frame(data=data)
        assert all(oe == 0 for oe in oes), 'Slave drove the line'
        assert dut.endat_dat_oe_o.value == 0
        # The next position request is answered
        result = await master.read_position()
        check_answer(result, 1234, 25)
        await master.recovery()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_master_stops_clock(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234)
    master = EndatMaster(dut, 25)
    result = await master.read_position()
    check_answer(result, 1234, 25)
    await master.recovery()
    check_health(dut, HEALTH_OK)
    # The master gives up part way through the position bits, the slave
    # releases the line once the clock has been idle for two periods
    await master.request(MODE_COMMAND)
    for _ in range(TCAL_CLOCKS + 10):
        _, oe = await master.clock()
        assert oe == 1
    await Timer(PERIOD * 3, 'ns')
    assert dut.endat_dat_oe_o.value == 0
    assert dut.endat_dat_o.value == 0
    check_health(dut, HEALTH_TIMEOUT)
    result = await master.read_position()
    check_answer(result, 1234, 25)
    check_health(dut, HEALTH_OK)
    await master.recovery()


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def endat_no_answer_when_bits_zero(dut):
    start_clock(dut)
    await setup(dut, 0, position=1234)
    master = EndatMaster(dut, 25)
    for _ in range(3):
        oes = await master.request(MODE_COMMAND)
        for _ in range(40):
            _, oe = await master.clock()
            oes.append(oe)
        assert all(oe == 0 for oe in oes), 'Slave drove the line'
        await Timer(master.gap_ns, 'ns')
    check_health(dut, HEALTH_TIMEOUT)


def test_endat_slave(build_dir):
    run_entity_test(
        'test_endat_slave', 'endat_slave',
        ['common/hdl/encoders/endat_slave.vhd',
         'common/hdl/encoders/endat_crc.vhd',
         'common/hdl/defines/support.vhd'],
        build_dir,
        parameters={'TCAL_CLOCKS': TCAL_CLOCKS, 'RECOVERY': RECOVERY})
