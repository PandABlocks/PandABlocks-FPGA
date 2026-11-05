#!/usr/bin/env python
"""A command arriving during a blocking wait is applied at the right time.

While sim_server blocks in ``select`` waiting for the next time-travel jump,
no clock edges run, so the simulated time stands still while the wall clock
moves on. The server catches the simulated time up before applying a command
that interrupts the wait. Here CLOCK2 is enabled part way through CLOCK1's
wait: CLOCK2 must be paced from its enable and CLOCK1 must keep its deadline.
"""
import os
from pathlib import Path

import cocotb
import panda_time_travel
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from panda_test_harness import PandaTestHarness
from panda_time_travel import TimeTravelState
from test_time_travel import CLOCK1_PERIOD, MAX_CYCLES, FakeClock, assert_close
from util import get_top, run_testtarget

# A command arrives this far into a wait for CLOCK1's next edge
COMMAND_OFFSET = 0.4
LATE_CLOCK_PERIOD = 18_750_000  # 0.15 s
# Real clock cycles advance the simulated time without advancing the fake
# wall clock, so the two drift apart by the cycles spent propagating events
# (MIN_TICKS per event plus up to JUMP_THRES while an event is too close to
# jump to). Well below the tens of millions of ticks a missed catch-up costs.
WALL_TOLERANCE = 50_000


@cocotb.test()
async def command_mid_wait_keeps_wall_clock_timing(dut):
    """A command arriving while the server blocks waiting for a jump takes
    effect at the simulated time that is due then, so a countdown it starts
    is paced from the command and the countdowns already running keep their
    deadlines."""
    fake_clock = FakeClock()
    panda_time_travel.time = fake_clock
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d',
                            do_time_travel=True)
    time_travel = test.time_travel
    freq = time_travel.fpga_clock_freq
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await ClockCycles(dut.clk_i, 4)

    bits = {name: test.metadata.get_bit_index(f'{name}.OUT')
            for name in ('CLOCK1', 'CLOCK2')}

    await test.reg_write('CLOCK1.PERIOD', CLOCK1_PERIOD)
    await test.reg_write('CLOCK1.ENABLE', 0x81)
    # as sim_server does after every command, so that the countdown starts
    # before the next wait
    time_travel.delay_wait()

    # (wall-clock time, simulated tick) of each rising edge
    edges = {name: [] for name in bits}
    previous = {name: 0 for name in bits}
    command_due = False
    command_sent = False
    edge = RisingEdge(dut.clk_i)
    for _ in range(MAX_CYCLES):
        await edge
        if command_due:
            # the client command arrives mid-wait: sim_server catches the
            # simulated time up with the wall clock before applying it
            before = time_travel.timestamp
            await time_travel.catch_up()
            caught_up = time_travel.timestamp - before
            assert abs(caught_up - COMMAND_OFFSET * freq) <= WALL_TOLERANCE, \
                f'Caught up {caught_up} ticks for {COMMAND_OFFSET} s'
            await test.reg_write('CLOCK2.PERIOD', LATE_CLOCK_PERIOD)
            await test.reg_write('CLOCK2.ENABLE', 0x81)
            time_travel.delay_wait()
            command_due = False
            command_sent = True

        await ReadOnly()
        bit_bus = dut.bit_bus.value.to_unsigned()
        for name, index in bits.items():
            level = (bit_bus >> index) & 1
            if level and not previous[name]:
                edges[name].append((fake_clock.now, time_travel.timestamp))
            previous[name] = level

        # stand in for the blocking select() in sim_server, interrupted once
        # by a command part way through a wait for CLOCK1
        timeout = time_travel.compute_timeout()
        if not command_sent and time_travel.state == TimeTravelState.WAITING \
                and timeout > COMMAND_OFFSET:
            fake_clock.now += COMMAND_OFFSET
            command_due = True
        else:
            fake_clock.now += timeout
        if len(edges['CLOCK1']) >= 2 and len(edges['CLOCK2']) >= 3:
            break
    else:
        raise AssertionError(f'Timed out: edges {edges}')

    assert command_sent, 'Never got to wait for CLOCK1'
    assert time_travel.njumps > 0, 'No jump happened'
    dut._log.info('Edges: %s', edges)

    for name, period in (('CLOCK1', CLOCK1_PERIOD),
                         ('CLOCK2', LATE_CLOCK_PERIOD)):
        # each clock keeps its period in simulated ticks
        for (_, first), (_, second) in zip(edges[name], edges[name][1:]):
            assert_close(second - first, period, f'{name} period')
        # and every edge happens at the wall-clock time its simulated tick
        # is due, counted from the clock's first edge
        wall_first, tick_first = edges[name][0]
        for wall, tick in edges[name][1:]:
            expected = (wall - wall_first) * freq
            assert abs(tick - tick_first - expected) <= WALL_TOLERANCE, \
                f'{name} edge at tick {tick - tick_first} after its first, ' \
                f'wall clock says {expected:.0f}'


def test_time_travel_command(build_dir):
    run_testtarget(
        'test_time_travel_command', get_top(), Path(build_dir), True)
