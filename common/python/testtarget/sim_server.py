#!/usr/bin/env python
import argparse
import cocotb
import enum
import logging
import os
import select
import socket
import time

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from collections import deque, OrderedDict
from dataclasses import dataclass, field
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget

OK_BYTES = b'\x00\x00\x00\x00'
ERR_BYTES = b'\xFF\xFF\xFF\xFF'


@dataclass
class TableBuffer:
    addr: int
    # in words
    capacity_words: int
    length_words: int = 0
    more_flag: bool = False
    target_field: str = ""


@dataclass
class TableState:
    current_buffer: TableBuffer = None
    next_buffer: TableBuffer = None
    queue: deque = field(default_factory=deque)
    nwords_queued: int = 0
    completed: bool = False
    block: int = 0
    num: int = 0
    address_reg: int = 0
    length_reg: int = 0


class COMMAND(enum.Enum):
    READ = ord('R')
    WRITE = ord('W')
    TABLE_WRITE = ord('T')
    GET_TABLE_QUEUED_WORDS = ord('Q')
    GET_PCAP_DATA = ord('D')


class SimServer(object):
    def __init__(self, dut, config_path):
        self.log = logging.getLogger(__class__.__name__)
        self.dut = dut
        self.clock = dut.clk_i
        self.pcap_buffer_size = 2 * 1024 * 1024
        self.pcap_n_buffers = 3
        self.pcap_mem_size = self.pcap_n_buffers * self.pcap_buffer_size
        self._pcap_buffer = 0
        self.pcap_next_buffer = 0
        self.pcap_current_buffer = 0
        self.pcap_next_buffer = 0
        self.pcap_timeout = 48
        self.table_buffer_size = 4 * 1024 * 1024
        self.table_n_buffers = 8
        self.table_mem_size = self.table_n_buffers * self.table_buffer_size
        self.table_next_buffer = 0
        self.table_available_buffers = \
            deque([TableBuffer(
                       i * self.table_buffer_size, self.table_buffer_size // 4)
                           for i in range(self.table_n_buffers)])
        self.test = PandaTestHarness(dut, config_path,
                                     pcap_mem_size=self.pcap_mem_size,
                                     table_mem_size=self.table_mem_size)
        self.pcap_arm_offsets = self.test.metadata.get_indexes('*REG.PCAP_ARM')
        self.pcap_acquiring = False
        self.pcap_data = bytearray()
        self.command = bytearray()
        self.find_table_instances()

    def find_table_instances(self):
        self.table_state = OrderedDict()
        for block_name, block in self.test.metadata.blocks.items():
            if block['has_table']:
                for num in range(block['n']):
                    self.table_state[(block['address'], num)] = \
                        TableState(
                            block=block['address'], num=num,
                            address_reg=block['fields']['TABLE']['args'][-2],
                            length_reg=block['fields']['TABLE']['args'][-1],
                        )

    async def interrupt_handler(self):
        # We run this in a separate task to prevent the following situation:
        # - the main task have pushed the first table buffer and continues to
        #   push more tables.
        # - Immediately after the first buffer is pushed, the ready table irq
        #   arrives, but the second table is pushed before the interrupt handler
        #   runs.
        # - The interrupt handler wrongly thinks that the first buffer is
        #   complete because there is a second buffer.
        # - A subsequent table push will be sent to hardware without it being
        #   ready.
        #
        # This can't happen in real hardware because the interrupt handler will
        # run much faster(compared to the time lapse between 2 table pushes).
        while True:
            irqs = await self.test.wait_for_irq(timeout=None)
            if irqs:
                await self.process_irqs(irqs)

    def wait_for_client(self):
        lsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        lsocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        lsocket.bind(('localhost', 9999))
        lsocket.listen(1)
        (csocket, addr) = lsocket.accept()
        lsocket.close()
        csocket.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        csocket.setblocking(False)
        self.client = csocket

    async def process_client(self) -> bool:
        was_first = len(self.command) == 0
        # optimization: check if there is data to read before calling recv, to
        # avoid having to catch the BlockingIOError exception in the common case
        # where there is no data.
        if not select.select([self.client], [], [], 0)[0]:
            return False

        new_data = self.client.recv(4096)
        if new_data == b'':
            return True

        self.command.extend(new_data)
        if len(self.command) > self.table_buffer_size + 8:
            self.log.error('Command too long, discarding message')
            self.command.clear()
            return False
        if was_first and self.command[0] not in COMMAND:
            self.log.error('Unknown command %d', self.command[0])
            self.log.error('Discarding message %s', repr(self.command))
            self.command.clear()
            return False

        await self.handle_command()
        return False

    async def handle_read(self):
        if len(self.command) < 4:
            return False

        block, num, reg = self.command[1:4]
        self.log.debug('READ command to (%d, %d, %d)', block, num, reg)
        val = await self.test.reg_read_raw(block, num, reg)
        self.send(val.to_bytes(4, 'little'))
        del self.command[:4]
        return True

    async def handle_write(self):
        if len(self.command) < 8:
            return False

        block, num, reg = self.command[1:4]
        if (block, num, reg) == self.pcap_arm_offsets:
            await self.pre_pcap_arm_hook()

        value = int.from_bytes(self.command[4:8], 'little')
        self.log.debug('WRITE command to (%d, %d, %d) =>  %d',
                       block, num, reg, value)
        await self.test.reg_write_raw(block, num, reg, value)
        del self.command[:8]
        return True

    async def handle_table_write(self):
        if len(self.command) < 8:
            return False

        length = int.from_bytes(self.command[4:8], 'little')
        tlength = length & 0x7fffffff
        if len(self.command) < 8 + tlength * 4:
            return False

        more_flag = bool((length >> 31) & 0x1)
        block, num, reg = self.command[1:4]
        self.log.debug('TABLE WRITE command to (%d, %d, %d) with %d words'
                       ' more_flag=%d',
                       block, num, reg, tlength, more_flag)
        assert (block, num) in self.table_state, 'Invalid table block/instance'
        table_state = self.table_state[(block, num)]
        if tlength == 0:
            self.log.debug('Table write with 0 length (table reset)')
            table_state.completed = False
            table_state.nwords_queued = 0
            self.release_all_table_buffers(table_state)
            await self.test.reg_write_raw(
                table_state.block, table_state.num, table_state.length_reg, 0)
            del self.command[:8]
            self.send(OK_BYTES)
            return True

        if table_state.completed:
            self.log.error('Table channel was completed, ignoring table write')
            del self.command[:8 + tlength * 4]
            self.send(ERR_BYTES)
            return True

        buffer = self.alloc_table_buffer()
        if buffer is None:
            self.log.error('No available buffers, ignoring table write')
            del self.command[:8 + tlength * 4]
            self.send(ERR_BYTES)
            return True

        assert tlength <= buffer.capacity_words, 'Data too large for buffer'
        buffer.length_words = tlength
        buffer.more_flag = more_flag
        block_name = self.test.metadata.get_block_name(block)
        buffer.target_field = f'{block_name}{num + 1}.TABLE'
        self.test.table_memory.mem[buffer.addr:buffer.addr + tlength * 4] = \
            self.command[8:8 + tlength * 4]

        if not await self.push_buffer(table_state, buffer):
            self.log.debug('Queuing table buffer 0x%X', buffer.addr)
            table_state.queue.appendleft(buffer)

        table_state.nwords_queued += tlength
        del self.command[:8 + tlength * 4]
        self.send(OK_BYTES)
        return True

    async def handle_get_table_queued_words(self):
        if len(self.command) < 4:
            return False

        block, num, reg = self.command[1:4]
        self.log.debug('GET TABLE QUEUED command for (%d, %d, %d)',
                       block, num, reg)
        assert (block, num) in self.table_state, 'Invalid table block/instance'
        table_state = self.table_state[(block, num)]
        queued = table_state.nwords_queued
        self.send(queued.to_bytes(4, 'little'))
        del self.command[:4]
        return True

    async def push_buffer(self, table_state, buffer):
        if table_state.current_buffer is None:
            table_state.current_buffer = buffer
        elif table_state.next_buffer is None:
            table_state.next_buffer = buffer
        else:
            return False

        self.log.debug('Pushing table buffer 0x%X to field %s',
                       buffer.addr, buffer.target_field)
        await self.test.reg_write_raw(
            table_state.block, table_state.num, table_state.address_reg,
            buffer.addr)
        await self.test.reg_write_raw(
            table_state.block, table_state.num, table_state.length_reg,
            buffer.length_words | (0x80000000 if buffer.more_flag else 0))

        return True

    def alloc_table_buffer(self):
        if not self.table_available_buffers:
            return None

        return self.table_available_buffers.popleft()

    def release_all_table_buffers(self, table_state):
        assert table_state is not None
        if table_state.current_buffer:
            self.release_table_buffer(table_state.current_buffer)
            table_state.current_buffer = None
        if table_state.next_buffer:
            self.release_table_buffer(table_state.next_buffer)
            table_state.next_buffer = None

        while table_state.queue:
            buffer = table_state.queue.pop()
            self.release_table_buffer(buffer)

    def release_table_buffer(self, buffer):
        assert buffer is not None
        self.log.debug('Releasing table buffer %X', buffer.addr)
        buffer.length_words = 0
        self.table_available_buffers.appendleft(buffer)

    def send(self, data):
        self.client.sendall(data)

    async def handle_get_pcap_data(self):
        if len(self.command) < 8:
            return False

        client_length = int.from_bytes(self.command[4:8], 'little')
        length = min(client_length, len(self.pcap_data))
        if length == 0 and not self.pcap_acquiring:
            # Indicates end of data
            length = 0xffffffff

        self.log.debug('GET PCAP DATA command returning %d bytes', length)
        self.send(length.to_bytes(4, 'little'))
        self.send(self.pcap_data[:length])
        del self.pcap_data[:length]
        del self.command[:8]
        return True

    async def pre_pcap_arm_hook(self):
        self.pcap_acquiring = True
        self.pcap_current_buffer = self.get_pcap_buffer()
        self.pcap_next_buffer = self.get_pcap_buffer()
        await self.test.reg_write('*DRV.PCAP_DMA_RESET', 0)
        await self.test.reg_write('*DRV.PCAP_BLOCK_SIZE', self.pcap_buffer_size)
        await self.test.reg_write('*DRV.PCAP_TIMEOUT', self.pcap_timeout)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.pcap_current_buffer)
        await self.test.reg_write('*DRV.PCAP_DMA_START', 0)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.pcap_next_buffer)

    async def handle_command(self):
        command_completed = True
        self.log.debug('Handling command, buffer: %s', self.command)
        while len(self.command) and command_completed:
            cmd = COMMAND(self.command[0])
            if cmd == COMMAND.READ:
                command_completed = await self.handle_read()
            elif cmd == COMMAND.WRITE:
                command_completed = await self.handle_write()
            elif cmd == COMMAND.TABLE_WRITE:
                command_completed = await self.handle_table_write()
            elif cmd == COMMAND.GET_TABLE_QUEUED_WORDS:
                command_completed = await self.handle_get_table_queued_words()
            elif cmd == COMMAND.GET_PCAP_DATA:
                command_completed = await self.handle_get_pcap_data()

    async def process_pcap_irq(self):
        self.log.debug('Handling PCAP IRQ')
        if not self.pcap_acquiring:
            self.log.error('Received PCAP IRQ while not acquiring')
            return

        # optimization: we read internal register directly instead of waiting
        # for the AXI read.
        #irq_status = await self.test.reg_read('*DRV.PCAP_IRQ_STATUS')
        irq_status = self.dut.pcap_inst.pcap_dma_inst.irq_status.value.to_unsigned()
        self.log.debug('PCAP IRQ STATUS: %X', irq_status)
        if irq_status & 0x1:
            self.pcap_acquiring = False

        if irq_status & 0x61:
            count = (irq_status >> 9) & 0x7fffff
            data_buffer = self.pcap_current_buffer
            self.pcap_current_buffer = self.pcap_next_buffer
            self.pcap_next_buffer = self.get_pcap_buffer()
            self.pcap_data.extend(
                self.test.pcap_memory.mem[data_buffer:data_buffer + count * 4])
            await self.test.reg_write(
                '*DRV.PCAP_DMA_ADDR', self.pcap_next_buffer)

    async def process_table_irq(self):
        self.log.debug('Handling TABLE IRQ')
        #irq_status = await self.test.reg_read('*REG.TABLE_IRQ_STATUS')
        # optimization/hack warning: we read internal register directly
        # instead of waiting for the AXI read.
        irq_status = self.dut.reg_inst.table_dma_irq.value.to_unsigned()
        self.dut.reg_inst.table_dma_irq.value = \
            self.dut.reg_inst.dma_irq_events_i.value.to_unsigned()
        self.log.debug('TABLE IRQ STATUS: 0x%X', irq_status)
        for i, ((block_name, num), table_state) in enumerate(self.table_state.items()):
            if irq_status & (1 << (i + 16)):
                self.log.debug('Got table completion')
                table_state.completed = True
                table_state.nwords_queued = 0
                self.release_all_table_buffers(table_state)
            elif irq_status & (1 << i):
                if table_state.current_buffer and table_state.next_buffer:
                    table_state.nwords_queued -=  \
                        table_state.current_buffer.length_words
                    self.release_table_buffer(table_state.current_buffer)
                    table_state.current_buffer = table_state.next_buffer
                    table_state.next_buffer = None
                    if table_state.queue:
                        buffer = table_state.queue.pop()
                        self.log.debug('Pushing queued table buffer 0x%X',
                                       buffer.addr)
                        await self.push_buffer(table_state, buffer)

    def get_pcap_buffer(self):
        buffer = self._pcap_buffer
        self._pcap_buffer += self.pcap_buffer_size
        if self._pcap_buffer >= self.pcap_mem_size:
            self._pcap_buffer = 0

        return buffer

    async def process_irqs(self, irqs):
        if irqs & 1:
            await self.process_pcap_irq()
        if irqs & 2:
            await self.process_table_irq()

    async def run(self):
        self.wait_for_client()
        cocotb.start_soon(Clock(self.clock, 1, 'ns').start(start_high=False))
        cocotb.start_soon(self.interrupt_handler())
        want_quit = False
        # Wait a couple clock cycles to let the DUT initialize
        await ClockCycles(self.clock, 2)
        edge = RisingEdge(self.clock)
        while not want_quit:
            await edge
            want_quit = await self.process_client()

        self.client.close()


@cocotb.test()
async def simulate(dut):
    sim = SimServer(dut, Path(os.getenv('AUTOGEN_PATH')) / 'config_d')
    log_level = os.getenv('sim_server_log_level')
    if log_level is not None:
        sim.log.setLevel(int(log_level))

    await sim.run()


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--build-dir', type=str, required=True,
        help='Path to the build directory')
    return parser.parse_args()


def main():
    args = parse_args()
    run_testtarget(
        'sim_server', get_top(), Path(args.build_dir),
        bool(os.getenv('dump_waveform')))


if __name__ == '__main__':
    main()
