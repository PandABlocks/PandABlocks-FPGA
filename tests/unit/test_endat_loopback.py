import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from entity_runner import run_entity_test

CLK_PERIOD = 16
FRAME_PERIOD = 1500
TCAL_TIMEOUT = 500
START_DELAY = 40
TCAL_CLOCKS = 2
RECOVERY = 100
# Longer than the round trip of a clock period, the master then sees its
# own last mode bit for more than a period after releasing the line
CABLE_DELAY = 10

HEALTH_OK = 0
HEALTH_TIMEOUT = 2
HEALTH_ERROR_BIT = 4

SOURCES = ['tests/unit/endat_loopback.vhd',
           'common/hdl/encoders/endat_master.vhd',
           'common/hdl/encoders/endat_slave.vhd',
           'common/hdl/encoders/endat_crc.vhd',
           'common/hdl/prescaler.vhd',
           'common/hdl/defines/support.vhd']


def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())


async def setup(dut, bits, delay_comp=0, position=0):
    """Reset master and slave, the clock must be running. The reset lasts
    longer than a round trip of the line so no clock edge from a previous
    frame reaches the slave once it is released, a slave starting while a
    frame is in flight would lose the next frame."""
    dut.reset_i.value = 1
    dut.slave_reset_i.value = 0
    dut.BITS.value = bits
    dut.CLK_PERIOD.value = CLK_PERIOD
    dut.FRAME_PERIOD.value = FRAME_PERIOD
    dut.DELAY_COMP.value = delay_comp
    dut.GENERATOR_ERROR.value = 0
    dut.posn_i.value = position
    await ClockCycles(dut.clk_i, 2 * CABLE_DELAY + 8)
    dut.reset_i.value = 0


async def wait_valid(dut, max_cycles=FRAME_PERIOD * 2):
    """Wait for the master to report a position, False if it does not. The
    slave only updates its health on the clock edge the master sends after
    its last sample, so allow for a round trip before checking it."""
    for _ in range(max_cycles):
        await RisingEdge(dut.clk_i)
        if dut.posn_valid_o.value == 1:
            await ClockCycles(dut.clk_i, 2 * CABLE_DELAY + 8)
            return True
    return False


def check_health(dut, health, slave_health=HEALTH_OK):
    assert dut.health_o.value.to_unsigned() == health
    assert dut.link_up_o.value == (1 if health == HEALTH_OK else 0)
    assert dut.slave_health_o.value.to_unsigned() == slave_health


async def read_positions(dut, bits, delay_comp=0):
    await setup(dut, bits, delay_comp)
    mask = (1 << bits) - 1
    for position in [0, 1, 1 << (bits - 1), mask, 0x5A5A5A5A & mask]:
        dut.posn_i.value = position & 0xFFFFFFFF
        # The slave latches the position at the start of a frame, skip the
        # frame that may be in flight
        assert await wait_valid(dut)
        assert await wait_valid(dut)
        # Both only keep 32 bits
        assert dut.posn_o.value.to_unsigned() == position & 0xFFFFFFFF
        check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=3, timeout_unit='ms')
async def loopback_position_read(dut):
    start_clock(dut)
    for bits in [13, 25, 32, 37, 63]:
        await read_positions(dut, bits)


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def loopback_delay_compensation(dut):
    start_clock(dut)
    for delay_comp in [2, 4]:
        await read_positions(dut, 25, delay_comp)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def loopback_error_bit(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234)
    assert await wait_valid(dut)
    check_health(dut, HEALTH_OK)
    dut.GENERATOR_ERROR.value = 1
    await ClockCycles(dut.clk_i, FRAME_PERIOD * 2)
    assert not await wait_valid(dut, FRAME_PERIOD)
    check_health(dut, HEALTH_ERROR_BIT)
    assert dut.posn_o.value.to_unsigned() == 1234
    dut.GENERATOR_ERROR.value = 0
    assert await wait_valid(dut)
    assert await wait_valid(dut)
    check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=1, timeout_unit='ms')
async def loopback_slave_absent(dut):
    start_clock(dut)
    await setup(dut, 25, position=1234)
    assert await wait_valid(dut)
    check_health(dut, HEALTH_OK)
    # The slave disappears, the master waits for the start bit in vain
    dut.slave_reset_i.value = 1
    await ClockCycles(dut.clk_i, FRAME_PERIOD * 2)
    assert not await wait_valid(dut, FRAME_PERIOD)
    check_health(dut, HEALTH_TIMEOUT, slave_health=HEALTH_TIMEOUT)
    dut.slave_reset_i.value = 0
    dut.posn_i.value = 4321
    assert await wait_valid(dut)
    assert await wait_valid(dut)
    assert dut.posn_o.value.to_unsigned() == 4321
    check_health(dut, HEALTH_OK)


# Both ends built for the same level of the error bit F1 meaning an error
@pytest.mark.parametrize('f1_error_value', ['0', '1'])
def test_endat_loopback(build_dir, f1_error_value):
    run_entity_test(
        'test_endat_loopback', 'endat_loopback', SOURCES, build_dir,
        parameters={'TCAL_TIMEOUT': TCAL_TIMEOUT, 'START_DELAY': START_DELAY,
                    'TCAL_CLOCKS': TCAL_CLOCKS, 'RECOVERY': RECOVERY,
                    'CABLE_DELAY': 0,
                    'F1_ERROR_VALUE': f"'{f1_error_value}'"})


def test_endat_loopback_cable(build_dir):
    run_entity_test(
        'test_endat_loopback', 'endat_loopback', SOURCES, build_dir,
        parameters={'TCAL_TIMEOUT': TCAL_TIMEOUT, 'START_DELAY': START_DELAY,
                    'TCAL_CLOCKS': TCAL_CLOCKS, 'RECOVERY': RECOVERY,
                    'CABLE_DELAY': CABLE_DELAY})
