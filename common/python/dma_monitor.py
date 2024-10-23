import cocotb

from cocotb.triggers import RisingEdge, FallingEdge
from pathlib import Path

SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


class DMAMonitor(object):
    def __init__(self, dut):
        self.dut = dut
        self.callbacks = []
        cocotb.start_soon(self.run())

    def add_callback(self, func):
        self.callbacks.append(func)

    async def run(self):
        while True:
            await RisingEdge(self.dut.pcap_dat_valid_o)
            self.value = self.dut.pcap_dat_o.value.signed_integer
            for callback in self.callbacks:
                callback(self.value)
