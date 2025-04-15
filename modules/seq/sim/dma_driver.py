import cocotb

from cocotb.triggers import RisingEdge
from collections import deque
from pathlib import Path


class DMADriver(object):
    def __init__(self, dut):
        self.dut = dut
        self.dut.dma_ack_i.value = 0
        self.dut.dma_done_i.value = 0
        self.dut.dma_data_i.value = 0
        self.dut.dma_valid_i.value = 0
        self.addr_values_map = {}
        cocotb.start_soon(self.run())

    def set_values(self, addr, values):
        self.addr_values_map[addr] = list(values)

    async def run(self):
        while True:
            await RisingEdge(self.dut.dma_req_o)
            await RisingEdge(self.dut.clk_i)
            addr = self.dut.dma_addr_o.value.to_unsigned()
            length = self.dut.dma_len_o.value.to_unsigned()
            print(f'addr: {addr}, length: {length}')
            values_i = 0
            if length == 0:
                length = 256

            self.dut.dma_ack_i.value = 1
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_ack_i.value = 0
            values_i = 0
            values = self.addr_values_map[addr]

            for i in range(length):
                self.dut.dma_data_i.value = values[values_i]
                values_i += 1
                if values_i > len(values):
                    raise EOFError('Ran out of values')

                self.dut.dma_valid_i.value = 1
                await RisingEdge(self.dut.clk_i)

            self.dut.dma_valid_i.value = 0
            self.dut.dma_done_i.value = 1
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_done_i.value = 0
