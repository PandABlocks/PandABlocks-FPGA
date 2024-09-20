import cocotb

from cocotb.triggers import RisingEdge, Edge, ReadOnly
from pathlib import Path

SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


class DMAMonitor(object):
    def __init__(self, dut):
        self.dut = dut
        self.value = 0
        self.ts = 0
        self.valid = 0
        cocotb.start_soon(self.run())
        cocotb.start_soon(self.check_valid())
        self.expect = []

    async def run(self):
        while True:
            await RisingEdge(self.dut.clk_i)
            if self.valid == 1:
                await ReadOnly()
                if self.valid == 1:
                    self.value = self.dut.pcap_dat_o.value.signed_integer
            self.ts += 1

    async def check_valid(self):
        while True:
            await RisingEdge(self.dut.pcap_dat_valid_o)
            self.valid = 1
            self.value = self.dut.pcap_dat_o.value.signed_integer
            await Edge(self.dut.pcap_dat_valid_o)
            self.valid = 0
