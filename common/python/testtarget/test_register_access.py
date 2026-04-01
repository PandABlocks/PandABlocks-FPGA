#!/usr/bin/env python
import cocotb
import os

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


@cocotb.test()
async def write_register_affecting_bit(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    outa_index = test.metadata.get_bit_index('BITS1.OUTA')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await RisingEdge(dut.clk_i)
    a = (dut.bit_bus.value.to_unsigned() >> outa_index) & 0x1
    assert a == 0, 'Initial value of BITS1.OUTA is not 0'
    await test.reg_write('BITS1.A', 1)
    await RisingEdge(dut.clk_i)
    a = (dut.bit_bus.value.to_unsigned() >> outa_index) & 0x1
    assert a == 1, 'BITS1.OUTA did not change to 1'


@cocotb.test()
@cocotb.parametrize(n=range(1, 9))
async def write_register_afecting_pos(dut, n=1):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    expected_val = n
    block = f'COUNTER{n}'
    pos_index = test.metadata.get_pos_index(f'{block}.OUT')
    val = dut.pos_bus[pos_index].value.to_unsigned()
    assert val == 0, \
        f'Initial value of {block}.OUT = {val} (expected 0)'
    await test.reg_write(f'{block}.SET', expected_val)
    await RisingEdge(dut.clk_i)
    val = dut.pos_bus[pos_index].value.to_unsigned()
    assert val == expected_val, \
        f'{block}.OUT = {val} (expected {expected_val})'


@cocotb.test()
async def read_register(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await RisingEdge(dut.clk_i)
    dummy_ticks = await test.reg_read('*REG.PCAP_TS_TICKS', -1)
    assert dummy_ticks == 0x11223344


@cocotb.test()
async def read_register_high_instance(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await RisingEdge(dut.clk_i)
    # this is testing that the simulation doesn't crash because of reading a
    # register of an instance with high number
    await test.reg_read('PULSE4.QUEUED')


def test_register_access(build_dir):
    run_testtarget(
        'test_register_access', get_top(), Path(build_dir),
        bool(os.getenv('dump_waveform')))
