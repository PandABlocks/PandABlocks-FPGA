#!/usr/bin/env python
"""Time travel keeps every tick-counting entity consistent.

Runs the testtarget design with time travel enabled, driven by a fake wall
clock that advances by whatever ``compute_timeout`` asks for (standing in for
the blocking ``select`` in sim_server). Two CLOCK blocks with different
periods, a PULSE block delaying CLOCK1 and a PCAP capture of the pulse
timestamps and gated sample count all have to agree on elapsed ticks.
"""
import os
import re
from pathlib import Path

import cocotb
import panda_time_travel
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge
from panda_test_harness import PandaTestHarness
from panda_time_travel import TimestampQueueModel
from util import get_top, run_testtarget

CLOCK1_PERIOD = 125_000_000  # 1 s at 125 MHz
CLOCK2_PERIOD = 87_500_000   # 0.7 s
PULSE_DELAY = 25_000_000     # 0.2 s
PULSE_WIDTH = 1000
# An event takes a few real cycles to propagate through the bit bus and the
# PCAP pipeline, and every jump is followed by MIN_TICKS real cycles.
TOLERANCE = 200
N_PULSES = 4
MAX_CYCLES = 100_000

PCAP_BUFFER_SIZE = 0x1000
PCAP_N_BUFFERS = 4
PCAP_TIMEOUT = 64
# capture words: TS_TRIG low, TS_TRIG high, SAMPLES
CAPTURE_MASKS = [0x240, 0x250, 0x260]
WORDS_PER_CAPTURE = len(CAPTURE_MASKS)


class FakeClock:
    def __init__(self):
        self.now = 1000.0

    def time(self):
        return self.now


class PcapReader:
    """Replicates the sim_server PCAP DMA buffer handling."""

    def __init__(self, dut, test):
        self.dut = dut
        self.test = test
        self.irq_status = dut.pcap_inst.pcap_dma_inst.irq_status
        self.irqs = Queue()
        self.data = []
        self._next_buffer = 0
        self.current_buffer = None
        self.next_buffer = None
        self.acquiring = False

    def alloc_buffer(self):
        buffer = self._next_buffer
        self._next_buffer = \
            (self._next_buffer + PCAP_BUFFER_SIZE) % \
            (PCAP_N_BUFFERS * PCAP_BUFFER_SIZE)
        return buffer

    async def arm(self):
        self.acquiring = True
        self.current_buffer = self.alloc_buffer()
        self.next_buffer = self.alloc_buffer()
        await self.test.reg_write('*DRV.PCAP_DMA_RESET', 0)
        await self.test.reg_write('*DRV.PCAP_BLOCK_SIZE', PCAP_BUFFER_SIZE)
        await self.test.reg_write('*DRV.PCAP_TIMEOUT', PCAP_TIMEOUT)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.current_buffer)
        await self.test.reg_write('*DRV.PCAP_DMA_START', 0)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.next_buffer)
        await self.test.reg_write('*REG.PCAP_START_WRITE', 0)
        for mask in CAPTURE_MASKS:
            await self.test.reg_write('*REG.PCAP_WRITE', mask)
        await self.test.reg_write('*REG.PCAP_ARM', 0)

    async def irq_listener(self):
        while True:
            irqs = await self.test.wait_for_irq(timeout=None)
            self.irqs.put_nowait(irqs)

    async def process_irqs(self):
        while not self.irqs.empty():
            irqs = self.irqs.get_nowait()
            if not irqs & 1:
                continue
            status = self.irq_status.value.to_unsigned()
            if status & 0x1:
                self.acquiring = False
            if status & 0x61:
                count = (status >> 9) & 0x7fffff
                index = self.current_buffer // 4
                self.data.extend(
                    int(w) for w in
                    self.test.pcap_memory.word_view[index:index + count])
                self.current_buffer = self.next_buffer
                self.next_buffer = self.alloc_buffer()
                await self.test.reg_write('*DRV.PCAP_DMA_ADDR',
                                          self.next_buffer)

    def captures(self):
        assert len(self.data) % WORDS_PER_CAPTURE == 0, \
            f'Partial capture in {self.data}'
        rows = [self.data[i:i + WORDS_PER_CAPTURE]
                for i in range(0, len(self.data), WORDS_PER_CAPTURE)]
        return [(ts_l | (ts_h << 32), samples) for ts_l, ts_h, samples in rows]


def assert_close(actual, expected, what):
    assert abs(actual - expected) <= TOLERANCE, \
        f'{what}: got {actual}, expected {expected} +- {TOLERANCE}'


def gate_high_ticks(rising_edges, high_ticks, start, end):
    """Ticks in [start, end) during which a signal that rises at each of
    rising_edges and stays high for high_ticks is high."""
    total = 0
    for rise in rising_edges:
        total += max(0, min(end, rise + high_ticks) - max(start, rise))
    return total


@cocotb.test()
async def entities_stay_consistent_across_jumps(dut):
    fake_clock = FakeClock()
    panda_time_travel.time = fake_clock
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d',
                            pcap_mem_size=PCAP_N_BUFFERS * PCAP_BUFFER_SIZE,
                            do_time_travel=True)
    time_travel = test.time_travel
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await ClockCycles(dut.clk_i, 4)

    bits = {name: test.metadata.get_bit_index(f'{name}.OUT')
            for name in ('CLOCK1', 'CLOCK2', 'PULSE1')}

    # PULSE1 delays CLOCK1 rising edges; parameters must be written before
    # enabling, as any write resets the block.
    await test.reg_write('PULSE1.TRIG', bits['CLOCK1'])
    await test.reg_write('PULSE1.DELAY', PULSE_DELAY)
    await test.reg_write('PULSE1.DELAY', 0, reg_arg_index=1)
    await test.reg_write('PULSE1.WIDTH', PULSE_WIDTH)
    await test.reg_write('PULSE1.WIDTH', 0, reg_arg_index=1)
    await test.reg_write('PULSE1.PULSES', 1)
    await test.reg_write('PULSE1.ENABLE', 0x81)  # ONE

    # PCAP captures the pulse timestamp and the number of CLOCK2 high ticks
    pcap = PcapReader(dut, test)
    cocotb.start_soon(pcap.irq_listener())
    await test.reg_write('PCAP.TRIG', bits['PULSE1'])
    await test.reg_write('PCAP.GATE', bits['CLOCK2'])
    await test.reg_write('PCAP.ENABLE', 0x81)
    await pcap.arm()

    await test.reg_write('CLOCK1.PERIOD', CLOCK1_PERIOD)
    await test.reg_write('CLOCK2.PERIOD', CLOCK2_PERIOD)
    await test.reg_write('CLOCK1.ENABLE', 0x81)
    await test.reg_write('CLOCK2.ENABLE', 0x81)

    # PULSE1 is instance 0 of the generate loop in the PULSE wrapper
    queue_models = [m for m in time_travel.models
                    if isinstance(m, TimestampQueueModel)
                    and re.search(r'pulse_inst\.gen\[0\]', m.path, re.IGNORECASE)]
    assert len(queue_models) == 1, \
        f'Cannot find PULSE1 queue in {[m.path for m in time_travel.models]}'
    pulse_queue_timestamp = queue_models[0].timestamp

    edges = {name: [] for name in bits}
    queue_timestamps = []
    previous = {name: 0 for name in bits}
    edge = RisingEdge(dut.clk_i)
    for _ in range(MAX_CYCLES):
        await edge
        await pcap.process_irqs()
        await ReadOnly()
        bit_bus = dut.bit_bus.value.to_unsigned()
        for name, index in bits.items():
            level = (bit_bus >> index) & 1
            if level and not previous[name]:
                edges[name].append(time_travel.timestamp)
                if name == 'CLOCK1':
                    queue_timestamps.append(
                        pulse_queue_timestamp.value.to_unsigned())
            previous[name] = level

        # stand in for the blocking select() in sim_server
        fake_clock.now += time_travel.compute_timeout()
        if len(edges['PULSE1']) >= N_PULSES and \
                len(pcap.data) >= N_PULSES * WORDS_PER_CAPTURE:
            break
    else:
        raise AssertionError(
            f'Timed out: edges {edges}, pcap data {pcap.data}')

    assert time_travel.njumps > 0, 'No jump happened'
    dut._log.info('Edges: %s', edges)
    dut._log.info('Captures: %s', pcap.captures())

    # Each CLOCK keeps its own period in simulated ticks
    for name, period in (('CLOCK1', CLOCK1_PERIOD), ('CLOCK2', CLOCK2_PERIOD)):
        assert len(edges[name]) >= 3, f'Not enough {name} edges: {edges}'
        for first, second in zip(edges[name], edges[name][1:]):
            assert_close(second - first, period, f'{name} period')

    # Every pulse follows a CLOCK1 edge by the programmed delay (the second
    # and later pulses are the ones that used to bunch up)
    assert len(edges['PULSE1']) >= N_PULSES
    for clock_ts, pulse_ts in zip(edges['CLOCK1'], edges['PULSE1']):
        assert_close(pulse_ts - clock_ts, PULSE_DELAY, 'PULSE1 delay')

    # The PULSE timestamp counter saw the same elapsed time as the CLOCK
    for first, second in zip(queue_timestamps, queue_timestamps[1:]):
        assert_close(second - first, CLOCK1_PERIOD, 'PULSE1 queue timestamp')

    # PCAP timestamps are spaced like the pulses, and SAMPLES counts the
    # CLOCK2 high ticks between captures
    captures = pcap.captures()[:N_PULSES]
    for (ts_a, _), (ts_b, _) in zip(captures, captures[1:]):
        assert_close(ts_b - ts_a, CLOCK1_PERIOD, 'PCAP TS_TRIG spacing')

    clock2_high = CLOCK2_PERIOD // 2  # WIDTH=0 means half period
    pulses = edges['PULSE1']
    for i in range(1, len(captures)):
        expected = gate_high_ticks(edges['CLOCK2'], clock2_high,
                                   pulses[i - 1], pulses[i])
        samples = captures[i][1]
        assert abs(samples - expected) <= 4 * TOLERANCE, \
            f'PCAP SAMPLES {i}: got {samples}, expected {expected}'


def test_time_travel(build_dir):
    run_testtarget(
        'test_time_travel', get_top(), Path(build_dir), True)
