import cocotb

from cocotb.triggers import RisingEdge
from pathlib import Path
SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


def int_or_hex(s: str) -> int:
    s = s.strip()
    if s.startswith('0x') or s.startswith('0X'):
        return int(s, 16)
    else:
        return int(s)


class DMADriver(object):
    def __init__(self, dut, module):
        self.dut = dut
        self.module = module
        self.dut.dma_ack_i.value = 0
        self.dut.dma_done_i.value = 0
        self.dut.dma_data_i.value = 0
        self.dut.dma_valid_i.value = 0
        self.addr_values_map = {}
        cocotb.start_soon(self.run())

    def load_data_for_address(self, addr, values):
        i = 0
        lvalues = list(values)
        while i < len(lvalues):
            chunk = lvalues[i:i + 256]
            self.addr_values_map[addr] = list(chunk)
            addr += 1024
            i += 256

    def search_and_load_data_for_address(self, addr):
        test_data_path = \
            MODULES_PATH / self.module / 'tests_assets' / f'{addr}.txt'
        with open(test_data_path) as test_data_file:
            data = [int_or_hex(item) for item in
                        test_data_file.read().splitlines()[1:]]

        self.load_data_for_address(addr, data)

    async def run(self):
        while True:
            await RisingEdge(self.dut.dma_req_o)
            await RisingEdge(self.dut.clk_i)
            addr = self.dut.dma_addr_o.value.to_unsigned()
            if addr not in self.addr_values_map:
                self.search_and_load_data_for_address(addr)

            length = self.dut.dma_len_o.value.to_unsigned()
            values_i = 0
            if length == 0:
                length = 256

            self.dut.dma_ack_i.value = 1
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_ack_i.value = 0
            values_i = 0
            values = self.addr_values_map[addr]

            for i in range(length - 1):
                self.dut.dma_data_i.value = values[values_i]
                values_i += 1
                if values_i > len(values):
                    raise EOFError('Ran out of values')

                self.dut.dma_valid_i.value = 1
                await RisingEdge(self.dut.clk_i)

            self.dut.dma_data_i.value = values[values_i]
            self.dut.dma_valid_i.value = 1
            self.dut.dma_done_i.value = 1
            await RisingEdge(self.dut.clk_i)
            self.dut.dma_valid_i.value = 0
            self.dut.dma_done_i.value = 0
