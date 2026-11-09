#!/usr/bin/env python
"""An event further away than the blocking timeout cap is still on time.

``compute_timeout`` caps the time the server may block at ``DEFAULT_TIMEOUT``
so that it wakes up now and then. Each wake-up moves the models forward by
the elapsed ticks without reaching the event, and the next timeout must be
computed from the distance left, not from the distance before the jump.
Here the cap is lowered below the CLOCK period so a single period takes
several capped waits.
"""
import os
from pathlib import Path

import cocotb
import panda_time_travel
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from panda_test_harness import PandaTestHarness
from test_time_travel import CLOCK1_PERIOD, MAX_CYCLES, FakeClock, assert_close
from test_time_travel_command import WALL_TOLERANCE
from util import get_top, run_testtarget

# well below the 1 s CLOCK period, and not a divisor of it
TIMEOUT_CAP = 0.3
N_EDGES = 3


@cocotb.test()
async def capped_waits_keep_wall_clock_timing(dut):
    fake_clock = FakeClock()
    panda_time_travel.time = fake_clock
    panda_time_travel.DEFAULT_TIMEOUT = TIMEOUT_CAP
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d',
                            do_time_travel=True)
    time_travel = test.time_travel
    freq = time_travel.fpga_clock_freq
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await ClockCycles(dut.clk_i, 4)

    clock1 = test.metadata.get_bit_index('CLOCK1.OUT')
    await test.reg_write('CLOCK1.PERIOD', CLOCK1_PERIOD)
    await test.reg_write('CLOCK1.ENABLE', 0x81)
    time_travel.delay_wait()

    # (wall-clock time, simulated tick) of each rising edge
    edges = []
    previous = 0
    edge = RisingEdge(dut.clk_i)
    for _ in range(MAX_CYCLES):
        await edge
        await ReadOnly()
        level = (dut.bit_bus.value.to_unsigned() >> clock1) & 1
        if level and not previous:
            edges.append((fake_clock.now, time_travel.timestamp))
        previous = level

        # stand in for the blocking select() in sim_server
        timeout = time_travel.compute_timeout()
        assert timeout <= TIMEOUT_CAP, f'Timeout {timeout} above the cap'
        fake_clock.now += timeout
        if len(edges) >= N_EDGES:
            break
    else:
        raise AssertionError(f'Timed out: edges {edges}')

    dut._log.info('Edges: %s', edges)
    assert time_travel.njumps > N_EDGES, 'Waits were not capped'
    wall_first, tick_first = edges[0]
    for (_, tick_a), (wall, tick) in zip(edges, edges[1:]):
        assert_close(tick - tick_a, CLOCK1_PERIOD, 'CLOCK1 period')
        # the edge happens at the wall-clock time its simulated tick is due
        expected = (wall - wall_first) * freq
        assert abs(tick - tick_first - expected) <= WALL_TOLERANCE, \
            f'CLOCK1 edge at tick {tick - tick_first} after its first, ' \
            f'wall clock says {expected:.0f}'


def test_time_travel_capped_wait(build_dir):
    run_testtarget(
        'test_time_travel_capped_wait', get_top(), Path(build_dir), True)
