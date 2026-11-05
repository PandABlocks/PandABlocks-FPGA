#!/usr/bin/env python
"""A pulse queued across the wrap of the PULSE timestamp still fires.

The timestamp_queue counter is 48 bits wide and the queued targets are
computed with the same width, so a target numerically below the current
timestamp is due once the counter has wrapped round to it. The time travel
model must see it as pending, or a jump to another block's event carries the
counter past it and the pulse is lost.

PULSE1 runs as a delay line (WIDTH 0): with a width the RTL's collision check
compares the wrapped timestamp against the next allowed trigger time without
wrapping, so it drops every trigger after the wrap.
"""
import os
import re
from pathlib import Path

import cocotb
import panda_time_travel
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from panda_test_harness import PandaTestHarness
from panda_time_travel import TimestampQueueModel
from test_time_travel import (
    CLOCK1_PERIOD,
    MAX_CYCLES,
    PULSE_DELAY,
    FakeClock,
    assert_close,
)
from util import get_top, run_testtarget

N_PULSES = 2


@cocotb.test()
async def pulse_queued_across_timestamp_wrap_fires(dut):
    fake_clock = FakeClock()
    panda_time_travel.time = fake_clock
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d',
                            do_time_travel=True)
    time_travel = test.time_travel
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await ClockCycles(dut.clk_i, 4)

    bits = {name: test.metadata.get_bit_index(f'{name}.OUT')
            for name in ('CLOCK1', 'PULSE1')}

    # PULSE1 delays CLOCK1
    await test.reg_write('PULSE1.TRIG', bits['CLOCK1'])
    await test.reg_write('PULSE1.DELAY', PULSE_DELAY)
    await test.reg_write('PULSE1.DELAY', 0, reg_arg_index=1)
    await test.reg_write('PULSE1.WIDTH', 0)
    await test.reg_write('PULSE1.WIDTH', 0, reg_arg_index=1)
    await test.reg_write('PULSE1.ENABLE', 0x81)  # ONE

    # PULSE1 is instance 0 of the generate loop in the PULSE wrapper
    queue_models = [m for m in time_travel.models
                    if isinstance(m, TimestampQueueModel)
                    and re.search(r'pulse_inst\.gen\[0\]', m.path, re.IGNORECASE)]
    assert len(queue_models) == 1, \
        f'Cannot find PULSE1 queue in {[m.path for m in time_travel.models]}'
    queue_timestamp = queue_models[0].timestamp

    # Put the counter close enough to its top that the target of the first
    # trigger, which CLOCK1 raises as soon as it is enabled, wraps round
    await RisingEdge(dut.clk_i)
    wrap = 1 << len(queue_timestamp)
    queue_timestamp.value = wrap - PULSE_DELAY // 2
    await test.reg_write('CLOCK1.PERIOD', CLOCK1_PERIOD)
    await test.reg_write('CLOCK1.ENABLE', 0x81)
    time_travel.delay_wait()

    edges = {name: [] for name in bits}
    queue_timestamps = []
    previous = {name: 0 for name in bits}
    edge = RisingEdge(dut.clk_i)
    for _ in range(MAX_CYCLES):
        await edge
        await ReadOnly()
        bit_bus = dut.bit_bus.value.to_unsigned()
        for name, index in bits.items():
            level = (bit_bus >> index) & 1
            if level and not previous[name]:
                edges[name].append(time_travel.timestamp)
                if name == 'CLOCK1':
                    queue_timestamps.append(queue_timestamp.value.to_unsigned())
            previous[name] = level

        # stand in for the blocking select() in sim_server
        fake_clock.now += time_travel.compute_timeout()
        if len(edges['PULSE1']) >= N_PULSES:
            break
    else:
        raise AssertionError(
            f'Timed out: {len(edges["CLOCK1"])} CLOCK1 edges, '
            f'{len(edges["PULSE1"])} PULSE1 edges')

    assert time_travel.njumps > 0, 'No jump happened'
    dut._log.info('Edges: %s, queue timestamps: %s', edges, queue_timestamps)

    # the first target did wrap, the second did not
    assert queue_timestamps[0] + PULSE_DELAY >= wrap, \
        f'First target did not wrap: {queue_timestamps[0]}'
    assert queue_timestamps[1] + PULSE_DELAY < wrap, \
        f'Second target wrapped: {queue_timestamps[1]}'
    for clock_ts, pulse_ts in zip(edges['CLOCK1'], edges['PULSE1']):
        assert_close(pulse_ts - clock_ts, PULSE_DELAY, 'PULSE1 delay')


def test_time_travel_wrap(build_dir):
    run_testtarget(
        'test_time_travel_wrap', get_top(), Path(build_dir), True)
