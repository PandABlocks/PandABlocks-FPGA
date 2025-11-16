import logging
import numpy as np

from axi import AxiLiteMaster, AxiWriteSlave, AxiReadSlave
from block_metadata import BlockMetadata
from cocotb.triggers import RisingEdge


class PandaTestHarness(object):
    def __init__(self, dut, configd_path,
                 pcap_mem_size=0x5000,
                 table_mem_size=0x5000):
        self.log = logging.getLogger(__class__.__name__)
        self.dut = dut
        self.clock = dut.clk_i
        self.metadata = BlockMetadata(configd_path)
        self.reg_axi = AxiLiteMaster(dut, 's_reg_axil', self.clock)
        self.init_signals(dut)
        self.pcap_axi = AxiWriteSlave(dut, 'm_pcap_axi', self.clock)
        self.pcap_memory = Memory(pcap_mem_size)
        self.table_memory = Memory(table_mem_size)
        self.pcap_axi.add_callback(self.handle_pcap_write)
        self.table_axi = AxiReadSlave(dut, 'm_table_axi', self.clock,
                                      self.table_read)
        self.want_quit = False

    async def wait_for_irq(self, timeout=1024):
        t = 0
        while True:
            await RisingEdge(self.clock)
            irqs_o = self.dut.irqs_o.value.to_unsigned()
            if irqs_o != 0:
                # make sure irq status is latched
                await RisingEdge(self.clock)
                return irqs_o

            t += 1
            if t >= timeout:
                return 0

    async def read_bit_changes(self):
        await self.reg_write('*REG.BIT_READ_RST', 0)
        changes = 0
        bitbus = 0
        for i in range(8):
            val = await self.reg_read('*REG.BIT_READ_VALUE')
            changes |= (val & 0xffff) << (i * 16)
            bitbus |= (val >> 16) << (i * 16)

        return changes, bitbus

    async def read_pos_changes(self):
        await self.reg_write('*REG.POS_READ_RST', 0)
        changes = await self.reg_read('*REG.POS_READ_CHANGES')
        pos_bus = []
        n_pos = len(self.dut.pos_bus)
        for _ in range(n_pos):
            val = await self.reg_read('*REG.POS_READ_VALUE')
            pos_bus.append(val)

        return changes, pos_bus

    def table_read(self, addr):
        assert addr % 4 == 0, "Address must be word-aligned"
        return self.table_memory.get_word(addr // 4)

    def handle_pcap_write(self, transaction):
        addr, data_list = transaction
        self.pcap_memory.add_burst(addr, data_list)

    async def reg_write(self, field, value, reg_arg_index=0):
        await self.reg_axi.write(
            self.metadata.reg_addr_from_field(field, reg_arg_index), value)

    async def reg_write_long_table(self, field, addr, length):
        await self.reg_axi.write(
            self.metadata.reg_addr_from_field(field, -2), addr)
        await self.reg_axi.write(
            self.metadata.reg_addr_from_field(field, -1), length)

    async def reg_read(self, field, reg_arg_index=0):
        return await self.reg_axi.read(
            self.metadata.reg_addr_from_field(field, reg_arg_index))

    def init_signals(self, dut):
        for sig in ('clk_i', 'reset_i'):
            dut[sig].value = 0

    async def setup_capture(self, masks,
                            # First 2 DMA buffers
                            addr1=0x1000, addr2=0x2000,
                            buffer_size=128):
        await self.reg_write('*DRV.PCAP_DMA_RESET', 0)
        await self.reg_write('*DRV.PCAP_BLOCK_SIZE', buffer_size)
        await self.reg_write('*DRV.PCAP_DMA_ADDR', addr1)
        await self.reg_write('*DRV.PCAP_DMA_START', 0)
        await self.reg_write('*DRV.PCAP_DMA_ADDR', addr2)
        await self.reg_write('*REG.PCAP_START_WRITE', 0)
        for mask in masks:
            await self.reg_write('*REG.PCAP_WRITE', mask)

        await self.reg_write('*REG.PCAP_ARM', 0x0)


class Memory(object):
    def __init__(self, size):
        self.log = logging.getLogger(__class__.__name__)
        self.size = size
        self.mem = bytearray(size)
        self.word_view = np.frombuffer(self.mem, dtype=np.uint32)

    def clear(self):
        self.word_view.fill(0)

    def set_word(self, word_index, value):
        self.word_view[word_index] = value

    def get_word(self, word_index):
        return int(self.word_view[word_index])

    def add_burst(self, addr, data_list):
        assert addr % 4 == 0, "Address must be word-aligned"
        index = addr // 4
        for data in data_list:
            self.word_view[index] = data
            index += 1

    def assert_content(self, addr, data_list):
        assert addr % 4 == 0, "Address must be word-aligned"
        index = addr // 4
        self.log.debug('Checking memory region - addr: 0x%08X, size: %d',
                       addr, len(data_list)*4)
        for expected in data_list:
            data = self.word_view[index]
            assert data == expected, \
                f'Memory mismatch at address 0x{index*4:08X}: ' + \
                f'expected 0x{expected:08X}, got 0x{data:08X}'
            index += 1
