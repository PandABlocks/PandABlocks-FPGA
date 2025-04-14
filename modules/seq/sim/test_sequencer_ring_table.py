#!/usr/bin/env python
import random
from collections import deque
from itertools import batched

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, ReadOnly
from cocotb.utils import get_sim_time
from cocotb_tools.runner import get_runner
from pathlib import Path

from common import get_top


TOP_PATH = get_top()


@cocotb.test()
async def builds(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await RisingEdge(dut.clk_i)


async def reset(dut):
    dut.data_i.value = 0
    dut.data_valid_i.value = 0
    dut.frame_ready_i.value = 0
    dut.reset_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.reset_i.value = 0


async def add_value(dut, value):
    done = False
    dut.data_i.value = value
    dut.data_valid_i.value = 1
    while not done:
        await RisingEdge(dut.clk_i)
        done = dut.data_ready_o.value == 1

    dut.data_valid_i.value = 0


@cocotb.test()
async def write_simple_entries_then_read(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await reset(dut)
    for i in range(16):
        await add_value(dut, i)

    await RisingEdge(dut.clk_i)
    dut.frame_ready_i.value = 1
    await RisingEdge(dut.clk_i)
    for part in batched(range(16), 4):
        while dut.frame_valid_o == 0:
            await RisingEdge(dut.clk_i)

        value = part[0] + (part[1] << 32) + (part[2] << 64) + (part[3] << 96)
        assert dut.seq_dout.value == value
        await RisingEdge(dut.clk_i)


@cocotb.test()
@cocotb.parametrize((("writer_loop_delay", "reader_loop_delay"),
                    [(0, 0), (16, 0), (0, 16), (16, 16)]))
async def write_and_read(dut, writer_loop_delay=0, reader_loop_delay=0,
                         n_reads=16):
    clkedge = RisingEdge(dut.clk_i)
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await reset(dut)
    expected = deque()
    dut._current_reads = 0
    async def write_loop(dut):
        await clkedge
        i = 1
        while True:
            while dut.data_ready_o.value == 1:
                value = i + (i<<32) + (i<<64) + (i<<96)
                i += 1
                print(f'write {value:x}')
                expected.appendleft(value)
                await add_value(dut, value & 0xFFFFFFFF)
                await add_value(dut, value>>32 & 0xFFFFFFFF)
                await add_value(dut, value>>64 & 0xFFFFFFFF)
                await add_value(dut, value>>96 & 0xFFFFFFFF)
                if writer_loop_delay:
                    await ClockCycles(dut.clk_i, writer_loop_delay)

            await clkedge

    async def read_loop(dut):
        await clkedge
        dut.frame_ready_i.value = 1
        while True:
            if dut.frame_valid_o.value == 1 and dut.frame_ready_i.value == 1:
                value = dut.seq_dout.value.to_unsigned()
                print(f'read {value:x}')
                dut._current_reads += 1
                assert value == expected.pop(), \
                    f'Unexpected value after {dut._current_reads} reads at' \
                    f' at {get_sim_time('ns')}'

                if reader_loop_delay:
                    dut.frame_ready_i.value = 0
                    await ClockCycles(dut.clk_i, reader_loop_delay)
                    dut.frame_ready_i.value = 1

            await clkedge

    cocotb.start_soon(write_loop(dut))
    cocotb.start_soon(read_loop(dut))
    while dut._current_reads < n_reads:
        await RisingEdge(dut.clk_i)


def test_sequencer_ring_table():
    runner = get_runner('nvc')
    runner.build(sources=[
                     TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'sim' /
                        'top_defines_gen.vhd',
                     TOP_PATH / 'common' / 'hdl' / 'defines' /
                        'top_defines.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'hdl' /
                         'sequencer_ring_table.vhd'
                 ],
                 build_dir='sim_sequencer_ring_table',
                 build_args=['--std=08'],
                 hdl_toplevel='sequencer_ring_table',
                 parameters={'SEQ_LEN': 8},
                 always=True)
    runner.test(hdl_toplevel='sequencer_ring_table',
                plusargs=['--wave=sequencer_ring_table.fst'],
                test_module='test_sequencer_ring_table')
