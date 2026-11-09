"""prescaled_timer in both start modes.

The pytest wrapper runs the cocotb tests once per value of the
EXPIRE_ON_ENABLE generic; the tests read the generic off the DUT and derive
their expectations from it.

Inputs are driven on falling edges and outputs sampled right after, so sample
``k`` shows the state after ``k`` enabled rising edges.
"""
import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly
from entity_runner import run_entity_test

PRESCALE = 2  # prescaler_rollover_i
ROLLOVER = 3  # timer_rollover_i
PERIOD = (PRESCALE + 1) * (ROLLOVER + 1)
# waveform tests run without a prescaler
WAVE_ROLLOVER = 8
LOW = 3


def expires_on_enable(dut):
    return bool(dut.EXPIRE_ON_ENABLE.value)


def first_expiry(dut, period):
    """Sample index of the first expiry after enabling."""
    return 0 if expires_on_enable(dut) else period - 1


async def setup(dut, prescale, rollover, low=None):
    dut.enable_i.value = 0
    dut.prescaler_rollover_i.value = prescale
    dut.timer_rollover_i.value = rollover
    if low is not None:
        dut.low_i.value = low
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())
    # a couple of disabled edges so the counters take their disabled values
    await ClockCycles(dut.clk_i, 2, rising=False)


async def run(dut, cycles, actions=None):
    """Enable the timer and return (expired_o, out_o) for each sample.

    ``actions`` maps a sample index to a callable driving inputs for that
    sample, called at the falling edge before it."""
    actions = actions or {}
    samples = []
    dut.enable_i.value = 1
    for k in range(cycles):
        if k in actions:
            actions[k]()
        await ReadOnly()
        samples.append((int(dut.expired_o.value), int(dut.out_o.value)))
        await FallingEdge(dut.clk_i)
    return samples


def strobes(samples):
    return [k for k, (expired, _) in enumerate(samples) if expired]


def levels(samples):
    return [out for _, out in samples]


# First so that nothing has driven low_i yet: the DUT is shared by the tests
# in this module and keeps the last value driven
@cocotb.test(timeout_time=10, timeout_unit='us')
async def default_low_never_clears_output(dut):
    await setup(dut, 0, WAVE_ROLLOVER)
    period = WAVE_ROLLOVER + 1
    first = first_expiry(dut, period)
    samples = await run(dut, first + 2 * period + 1)
    assert levels(samples) == [0] * (first + 1) + [1] * (2 * period)


@cocotb.test(timeout_time=10, timeout_unit='us')
async def counters_take_disabled_values(dut):
    await setup(dut, PRESCALE, ROLLOVER)
    expected = (ROLLOVER, PRESCALE) if expires_on_enable(dut) else (0, 0)
    assert (dut.counter.value.to_unsigned(),
            dut.precounter.value.to_unsigned()) == expected
    assert dut.expired_o.value == 0
    assert dut.out_o.value == 0


@cocotb.test(timeout_time=10, timeout_unit='us')
async def expires_every_period(dut):
    await setup(dut, PRESCALE, ROLLOVER)
    first = first_expiry(dut, PERIOD)
    samples = await run(dut, first + 3 * PERIOD)
    assert strobes(samples) == [first, first + PERIOD, first + 2 * PERIOD]


@cocotb.test(timeout_time=10, timeout_unit='us')
async def rollover_change_on_expiry_applies_to_next_period(dut):
    await setup(dut, PRESCALE, ROLLOVER)
    first = first_expiry(dut, PERIOD)

    def shorten():
        dut.timer_rollover_i.value = 1

    # as SEQ does: the new rollover is registered on the expiry edge, so it is
    # driven for the sample after the one that showed the strobe, and the
    # period that starts at that expiry already has the new length
    short_period = (PRESCALE + 1) * 2
    samples = await run(dut, first + 3 * short_period + 1,
                        actions={first + 1: shorten})
    assert strobes(samples) == [first + n * short_period for n in range(4)]


@cocotb.test(timeout_time=10, timeout_unit='us')
async def output_waveform(dut):
    await setup(dut, 0, WAVE_ROLLOVER, LOW)
    period = WAVE_ROLLOVER + 1
    first = first_expiry(dut, period)
    samples = await run(dut, first + 2 * period + 1)
    # out_o rises the edge after the expiry and falls the edge after
    # counter = low, so it is high for low + 1 ticks
    expected = [0] * (first + 1)
    for _ in range(2):
        expected += [1] * (LOW + 1) + [0] * (period - LOW - 1)
    assert levels(samples) == expected


@cocotb.test(timeout_time=10, timeout_unit='us')
async def disable_clears_output(dut):
    await setup(dut, 0, WAVE_ROLLOVER, LOW)
    first = first_expiry(dut, WAVE_ROLLOVER + 1)

    def disable():
        dut.enable_i.value = 0

    samples = await run(dut, first + 4, actions={first + 2: disable})
    assert levels(samples)[first + 1] == 1
    # the strobe drops with enable, the registered output on the next edge
    assert samples[first + 2:] == [(0, 1), (0, 0)]


@pytest.mark.parametrize('expire_on_enable', [False, True])
def test_prescaled_timer(build_dir, expire_on_enable):
    run_entity_test(
        'test_prescaled_timer', 'prescaled_timer',
        ['common/hdl/prescaled_timer.vhd'],
        build_dir,
        parameters={'EXPIRE_ON_ENABLE': str(expire_on_enable).lower()})
