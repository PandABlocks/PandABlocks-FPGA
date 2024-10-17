import cocotb

from cocotb.triggers import RisingEdge
from collections import deque
from pathlib import Path

SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


class DMADriver(object):
    def __init__(self, dut, module):
        self.dut = dut
        self.dut.dma_ack_i.value = 0
        self.dut.dma_done_i.value = 0
        self.dut.dma_data_i.value = 0
        self.dut.dma_valid_i.value = 0
        self.module = module
        cocotb.start_soon(self.run())

    async def run(self):
        while True:
            await RisingEdge(self.dut.dma_req_o)
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_ack_i.value = 1
            addr = self.dut.dma_addr_o.value.integer
            length = self.dut.dma_len_o.value.integer
            data = deque([int(item) for item in open(
                         MODULES_PATH / self.module /
                         f'{self.module.upper()}_{addr}.txt',
                         'r').read().splitlines()[1:]])
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_ack_i.value = 0
            for i in range(length):
                self.dut.dma_data_i.value = data.popleft()
                self.dut.dma_valid_i.value = 1
                await RisingEdge(self.dut.clk_i)

            self.dut.dma_valid_i.value = 0
            self.dut.dma_done_i.value = 1
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_done_i.value = 0
