#!/usr/bin/env python
import cocotb
import os
import pytest

from enum import Enum
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, ReadOnly
from cocotb_tools.runner import get_runner
from pathlib import Path

from common import get_top
from dma_driver import DMADriver


TOP_PATH = get_top()


class State(Enum):
    IDLE = 0
    WAIT_ENABLE = 1
    WAIT_TRIGGER = 2
    PHASE1 = 3
    PHASE2 = 4
    RESETTING = 5


async def wait_for_state(dut, state, timeout=1024):
    i = 0
    while dut.state.value.to_unsigned() != state.value:
        await RisingEdge(dut.clk_i)
        i += 1
        if timeout and i > timeout:
            raise TimeoutError(f'Timeout waiting for state {state.name}')


async def assert_output_repeats(dut, state, output='a', value=1, repeats=1):
    for _ in range(repeats):
        assert dut.state.value.to_unsigned() == state.value
        assert getattr(dut, f'out{output}_o').value == value, \
            f'Expected out{output}_o to be {value}'
        await RisingEdge(dut.clk_i)


@cocotb.test()
async def builds(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await RisingEdge(dut.clk_i)


async def reset(dut):
    dut.enable_i.value = 0
    dut.prescale.value = 0
    dut.repeats.value = 0
    dut.enable_i.value = 0
    dut.table_length.value = 0
    dut.table_length_wstb.value = 1
    await RisingEdge(dut.clk_i)
    dut.table_length_wstb.value = 0


async def setup_table(dut, address, length, more):
    dut.table_address.value = address
    dut.table_length.value = length | (1 << 31 if more else 0)
    dut.table_address_wstb.value = 1
    dut.table_length_wstb.value = 1
    await RisingEdge(dut.clk_i)
    dut.table_address_wstb.value = 0
    dut.table_length_wstb.value = 0


@cocotb.test()
@cocotb.parametrize((('repeats'), [1, 3]))
async def three_evenly_spaced_pulses(dut, repeats=1):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    clkedge = RisingEdge(dut.clk_i)
    await reset(dut)
    dut.repeats.value = repeats
    dma_driver = DMADriver(dut)
    # OUT = 0x1 (OUT1=A), TRIGGER = 0x0 (Immediate), REPEATS = 0x0003
    dma_driver.set_values(0, (0x100003, 0, 5, 5))
    await setup_table(dut, 0, 1*16, more=False)
    await wait_for_state(dut, State.WAIT_ENABLE)
    dut.enable_i.value = 1
    assert dut.active_o.value == 0
    await wait_for_state(dut, State.PHASE1)
    assert dut.active_o.value == 1
    for _ in range(repeats):
        for _ in range(3):
            await assert_output_repeats(dut, State.PHASE1, 'a', 1, 5)
            await assert_output_repeats(dut, State.PHASE2, 'a', 0, 5)

    assert dut.active_o.value == 0
    await wait_for_state(dut, State.IDLE, timeout=2)
    await ClockCycles(dut.clk_i, 4)


@cocotb.test()
async def simple_streaming(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    clkedge = RisingEdge(dut.clk_i)
    await reset(dut)
    dut.repeats.value = 1
    dma_driver = DMADriver(dut)
    dma_driver.set_values(0, (
        # OUT = 0x40 (OUT2=A) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 20
        0x04000001, 0, 0, 20,
        # OUT = 0x00 (OUT2=0) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 5
        0x00000001, 0, 0, 5,
    ))
    dma_driver.set_values(0x100, (
        # OUT = 0x40 (OUT2=B) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 20
        0x08000001, 0, 0, 20,
        # OUT = 0x00 (OUT2=0) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 10
        0x00000001, 0, 0, 5,
    ))
    await setup_table(dut, 0, 2*16, more=True)
    await wait_for_state(dut, State.WAIT_ENABLE)

    async def check_sequencer(dut):
        await wait_for_state(dut, State.PHASE2, timeout=8)
        await assert_output_repeats(dut, State.PHASE2, 'a', 1, 20)
        await assert_output_repeats(dut, State.PHASE2, 'a', 0, 5)
        await assert_output_repeats(dut, State.PHASE2, 'b', 1, 20)
        await assert_output_repeats(dut, State.PHASE2, 'b', 0, 5)

    cocotb.start_soon(check_sequencer(dut))
    dut.enable_i.value = 1
    await clkedge
    await setup_table(dut, 0x100, 2*16, more=False)
    await clkedge
    await wait_for_state(dut, State.IDLE)
    await ClockCycles(dut.clk_i, 4)


@cocotb.test()
async def simple_streaming_disabled(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    clkedge = RisingEdge(dut.clk_i)
    await reset(dut)
    dut.repeats.value = 1
    dma_driver = DMADriver(dut)
    entries = (
        # OUT = 0x40 (OUT2=A) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 20
        0x04000001, 0, 0, 20,
        # OUT = 0x00 (OUT2=0) TRIGGER = 0x0 (Immediate) REPEATS = 0x0001
        # TIME2 = 5
        0x00000001, 0, 0, 5,
    ) * 2
    dma_driver.set_values(0, entries)
    await setup_table(dut, 0, len(entries) * 4, more=True)
    await wait_for_state(dut, State.WAIT_ENABLE)

    async def check_sequencer(dut):
        await wait_for_state(dut, State.PHASE2, timeout=8)
        await assert_output_repeats(dut, State.PHASE2, 'a', 1, 1)

    cocotb.start_soon(check_sequencer(dut))
    dut.enable_i.value = 1
    await clkedge
    dut.enable_i.value = 0
    await clkedge
    await clkedge
    assert dut.state.value.to_unsigned() == State.RESETTING.value
    await wait_for_state(dut, State.IDLE)


def test_seq():
    runner = get_runner('nvc')
    runner.build(sources=[
                     TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'sim' /
                        'top_defines_gen.vhd',
                     TOP_PATH / 'common' / 'hdl' / 'defines' /
                        'top_defines.vhd',
                     TOP_PATH / 'common' / 'hdl' /
                        'table_read_engine_client_transfer_manager.vhd',
                     TOP_PATH / 'common' / 'hdl' /
                        'table_read_engine_client_length_manager.vhd',
                     TOP_PATH / 'common' / 'hdl' /
                        'table_read_engine_client.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'hdl' /
                         'sequencer_defines.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'hdl' /
                         'sequencer_prescaler.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'hdl' /
                         'sequencer_ring_table.vhd',
                     TOP_PATH / 'modules' / 'seq' / 'hdl' / 'seq.vhd',
                 ],
                 build_args=['--std=08'],
                 build_dir='sim_seq',
                 hdl_toplevel='seq',
                 always=True)
    runner.test(hdl_toplevel='seq',
                test_args=['--wave=seq.fst'],
                test_module='test_seq')
