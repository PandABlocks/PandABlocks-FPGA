#!/usr/bin/env python
import cocotb
import os

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


@cocotb.test()
async def pgen_run_many_tables(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    # Set expected pattern in memory
    for i in range(16):
        test.table_memory.set_word(i, i)

    for i in range(16):
        test.table_memory.set_word(i + 0x1000 // 4, i + 16)

    for i in range(16):
        test.table_memory.set_word(i + 0x2000 // 4, i + 32)

    pos_index = test.metadata.get_pos_index('PGEN1.OUT')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await test.reg_write('PGEN1.ENABLE', 0x80)
    await test.reg_write('PGEN1.TRIG', 0x80)
    await RisingEdge(dut.clk_i)
    # bit 31 means this is not the last table
    await test.reg_write_long_table('PGEN1.TABLE', 0x0, 16 | (1 << 31))
    await ClockCycles(dut.clk_i, 8)
    await test.reg_write('PGEN1.ENABLE', 0x81)
    await RisingEdge(dut.clk_i)
    expected_val = 0
    async def trigger_pgen():
        await test.reg_write('PGEN1.TRIG', 0x81)
        await RisingEdge(dut.clk_i)
        await test.reg_write('PGEN1.TRIG', 0x80)
        await RisingEdge(dut.clk_i)

    for _ in range(8):
        await trigger_pgen()
        assert dut.pos_bus[pos_index].value.to_unsigned() == expected_val
        expected_val += 1

    await test.reg_write_long_table('PGEN1.TABLE',  0x1000, 16 | (1 << 31))
    for _ in range(8):
        await trigger_pgen()
        assert dut.pos_bus[pos_index].value.to_unsigned() == expected_val
        expected_val += 1

    await test.reg_write_long_table('PGEN1.TABLE',  0x2000, 16)
    for _ in range(32):
        await trigger_pgen()
        assert dut.pos_bus[pos_index].value.to_unsigned() == expected_val
        expected_val += 1

    await test.reg_write('PGEN1.ENABLE', 0x80)
    await RisingEdge(dut.clk_i)


def test_pgen_streaming(build_dir):
    run_testtarget(
        'test_pgen_streaming', get_top(), Path(build_dir),
        bool(os.getenv('dump_waveform')))
