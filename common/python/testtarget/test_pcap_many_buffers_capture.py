import cocotb
import os

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.utils import get_sim_time
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


@cocotb.test()
async def pcap_many_buffers_capture(dut):
    test = PandaTestHarness(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start(start_high=False))
    await test.reg_write('PCAP.TRIG', 0x80)
    await test.reg_write('PCAP.ENABLE', 0x81)
    # Capture trigger timestamp
    await test.setup_capture(
        [0x240], addr1=0x1000, addr2=0x2000, buffer_size=128)
    await RisingEdge(dut.clk_i)
    expected_ts = []
    time_offset = int(get_sim_time('ns')) - 4
    # Generate data to fill the first buffer
    for _ in range(32):
        await test.reg_write('PCAP.TRIG', 0x81)
        expected_ts.append(int(get_sim_time('ns') - time_offset))
        await test.reg_write('PCAP.TRIG', 0x80)

    irqs = await test.wait_for_irq()
    assert irqs == 1, 'PCAP interrupt expected'
    status = await test.reg_read('*DRV.PCAP_IRQ_STATUS')
    assert status == 0x40 | (32 << 9), \
        'PCAP IRQ STATUS does not indicate buffer full and n samples'
    await test.reg_write('*DRV.PCAP_DMA_ADDR', 0x3000)
    # Generate data to fill the second buffer and a bit of the next one
    for _ in range(34):
        await test.reg_write('PCAP.TRIG', 0x81)
        expected_ts.append(int(get_sim_time('ns') - time_offset))
        await test.reg_write('PCAP.TRIG', 0x80)

    await test.reg_write('PCAP.ENABLE', 0x80)
    irqs = await test.wait_for_irq()
    assert irqs == 1, 'PCAP interrupt expected'
    status = await test.reg_read('*DRV.PCAP_IRQ_STATUS')
    assert status == 0x40 | (32 << 9), \
        'PCAP IRQ STATUS does not indicate just buffer full and n samples'
    # Check that the final interrupt doesn't arrive until we push the next
    # address, this verifies the fix for issue #56
    await ClockCycles(dut.clk_i, 64)
    status = await test.reg_read('*DRV.PCAP_IRQ_STATUS')
    assert status & 1 == 0, 'Last interrupt arrived too early'
    await test.reg_write('*DRV.PCAP_DMA_ADDR', 0x4000)
    await ClockCycles(dut.clk_i, 4)
    status = await test.reg_read('*DRV.PCAP_IRQ_STATUS')
    assert status == 0x1 | (2 << 9), \
        'PCAP IRQ STATUS does not indicate just completion and n samples'
    test.pcap_memory.assert_content(0x1000, expected_ts[0:32])
    test.pcap_memory.assert_content(0x2000, expected_ts[32:64])
    test.pcap_memory.assert_content(0x3000, expected_ts[64:66])


def test_pcap_many_buffers_capture(build_dir):
    run_testtarget(
        'test_pcap_many_buffers_capture', get_top(), Path(build_dir),
        bool(os.getenv('dump_waveform')))
