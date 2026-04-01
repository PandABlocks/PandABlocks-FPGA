#!/usr/bin/env python
import cocotb
import os

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


@cocotb.test()
async def pcap_one_buffer_capture(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await test.reg_write('PCAP.ENABLE', 0x81)
    await test.reg_write('CLOCK1.ENABLE', 0x81)
    clock_bitout = test.metadata.get_bit_index('CLOCK1.OUT')
    await test.reg_write('PCAP.TRIG', clock_bitout)
    # Capture trigger timestamp
    await test.setup_capture([0x240])
    await test.reg_write('CLOCK1.PERIOD', 2)
    await ClockCycles(dut.clk_i, 16)
    await test.reg_write('CLOCK1.PERIOD', 0)
    await ClockCycles(dut.clk_i, 2)
    await test.reg_write('PCAP.ENABLE', 0x80)
    # Allow some time for the data to be written in memory
    await ClockCycles(dut.clk_i, 32)
    # if timing between arming and first trigger changes, the offset in the
    # list will need to be adjusted.
    test.pcap_memory.assert_content(0x1000, [8 + i*2 for i in range(10)])


def test_pcap_one_buffer_capture(build_dir):
    run_testtarget(
        'test_pcap_one_buffer_capture', get_top(), Path(build_dir),
        bool(os.getenv('dump_waveform')))
