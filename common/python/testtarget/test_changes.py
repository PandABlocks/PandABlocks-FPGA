#!/usr/bin/env python
import cocotb
import os

from cocotb.clock import Clock
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


@cocotb.test()
async def bit_changes_reflect_bit_change(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    outa_index = test.metadata.get_bit_index('BITS.OUTA')
    changes, bitbus = await test.read_bit_changes()
    assert bitbus & (1 << outa_index) == 0
    assert changes & (1 << outa_index) == 0
    await test.reg_write('BITS.A', 1)
    changes, bitbus = await test.read_bit_changes()
    assert bitbus & (1 << outa_index)
    assert changes & (1 << outa_index)


@cocotb.test()
async def pos_changes_reflect_pos_change(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    pos_index = test.metadata.get_pos_index('COUNTER1.OUT')
    changes, pos_bus = await test.read_pos_changes()
    assert changes & (1 << pos_index) == 0
    assert pos_bus[pos_index] == 0
    expected_val = 42
    await test.reg_write('COUNTER1.SET', expected_val)
    changes, pos_bus = await test.read_pos_changes()
    assert changes & (1 << pos_index)
    assert pos_bus[pos_index] == expected_val


def test_register_access(build_dir):
    run_testtarget(
        'test_changes', get_top(), Path(build_dir),
        bool(os.getenv('dump_waveform')))
