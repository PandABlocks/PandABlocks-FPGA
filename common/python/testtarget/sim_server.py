#!/usr/bin/env python
import argparse
import cocotb
import enum
import logging
import os
import socket

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from pathlib import Path
import sys

sys.path.insert(1, str(Path(__file__).parent.resolve()))
from panda_test_harness import PandaTestHarness
from util import get_top, run_testtarget


class COMMAND(enum.Enum):
    READ = ord('R')
    WRITE = ord('W')
    TABLE_WRITE = ord('T')
    GET_PCAP_DATA = ord('D')


class SimServer(object):
    def __init__(self, dut, config_path):
        self.log = logging.getLogger(__class__.__name__)
        self.dut = dut
        self.clock = dut.clk_i
        self.ticks_per_iteration = 1
        self.pcap_buffer_size = 2 * 1024 * 1024
        self.pcap_mem_size = 3 * self.pcap_buffer_size
        self.pcap_next_buffer = 0
        self.pcap_first_buffer = 0
        self.pcap_second_buffer = 0
        self.pcap_timeout = 128
        self.table_buffer_size = 8 * 1024 * 1024
        self.table_mem_size = 3 * self.table_buffer_size
        self.table_next_buffer = 0
        self.test = PandaTestHarness(dut, config_path,
                                     pcap_mem_size=self.pcap_mem_size,
                                     table_mem_size=self.table_mem_size)
        self.pcap_arm_offsets = self.test.metadata.get_indexes('*REG.PCAP_ARM')
        self.pcap_acquiring = False
        self.pcap_data = bytearray()
        self.command = bytearray()

    def wait_client(self):
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
        addr = self.test.metadata.reg_addr(block, num, reg)
        val = await self.test.reg_axi.read(addr)
        self.client.sendall(val.to_bytes(4, 'little'))
        del self.command[:4]
        return True

    async def handle_write(self):
        if len(self.command) < 8:
            return False

        block, num, reg = self.command[1:4]
        if (block, num, reg) == self.pcap_arm_offsets:
            await self.pre_pcap_arm_hook()

        addr = self.test.metadata.reg_addr(block, num, reg)
        value = int.from_bytes(self.command[4:8], 'little')
        self.log.debug('WRITE command to (%d, %d, %d) =>  %d',
                       block, num, reg, value)
        await self.test.reg_axi.write(addr, value)
        del self.command[:8]
        return True

    async def handle_table_write(self):
        if len(self.command) < 8:
            return False

        length = int.from_bytes(self.command[4:8], 'little')
        tlength = length & 0x7fffffff
        more_flag = (length >> 31) & 0x1
        if len(self.command) < 8 + tlength * 4:
            return False

        block, num, reg = self.command[1:4]
        self.log.debug('TABLE WRITE command to (%d, %d, %d) with %d bytes'
                       ' more_flag=%d',
                       block, num, reg, tlength, more_flag)
        buffer = self.get_next_table_buffer()
        self.test.table_memory.mem[buffer:buffer + tlength * 4] = \
            self.command[8:8 + tlength * 4]
        block_name = self.test.metadata.get_block_name(block)
        await self.test.reg_write_long_table(
            f'{block_name}{num + 1}.TABLE', buffer, length)
        del self.command[:8 + tlength * 4]
        return True

    def get_next_table_buffer(self):
        buffer = self.table_next_buffer
        self.table_next_buffer += self.table_buffer_size
        if self.table_next_buffer >= self.table_mem_size:
            self.table_next_buffer = 0

        return buffer

    async def handle_get_pcap_data(self):
        if len(self.command) < 8:
            return False

        client_length = int.from_bytes(self.command[4:8], 'little')
        length = min(client_length, len(self.pcap_data))
        if length == 0 and not self.pcap_acquiring:
            # Indicates end of data
            length = 0xffffffff

        self.log.debug('GET PCAP DATA command returning %d bytes', length)
        self.client.sendall(length.to_bytes(4, 'little'))
        self.client.sendall(self.pcap_data[:length])
        self.pcap_data = self.pcap_data[length:]
        del self.command[:8]
        return True

    async def pre_pcap_arm_hook(self):
        self.pcap_acquiring = True
        self.pcap_first_buffer = self.get_next_pcap_buffer()
        self.pcap_second_buffer = self.get_next_pcap_buffer()
        await self.test.reg_write('*DRV.PCAP_DMA_RESET', 0)
        await self.test.reg_write('*DRV.PCAP_BLOCK_SIZE', self.pcap_buffer_size)
        await self.test.reg_write('*DRV.PCAP_TIMEOUT', self.pcap_timeout)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.pcap_first_buffer)
        await self.test.reg_write('*DRV.PCAP_DMA_START', 0)
        await self.test.reg_write('*DRV.PCAP_DMA_ADDR', self.pcap_second_buffer)

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
            elif cmd == COMMAND.GET_PCAP_DATA:
                command_completed = await self.handle_get_pcap_data()

    async def handle_pcap_irq(self):
        self.log.debug('Handling PCAP IRQ')
        if not self.pcap_acquiring:
            self.log.error('Received PCAP IRQ while not acquiring')
            return

        #status = await self.test.reg_read('*DRV.PCAP_IRQ_STATUS')
        # optimization: we read internal register directly instead of waiting
        # for the AXI read.
        status = self.dut.pcap_inst.pcap_dma_inst.irq_status.value.to_unsigned()
        self.log.debug('PCAP IRQ STATUS: %X', status)
        if status & 0x1:
            self.pcap_acquiring = False

        if status & 0x61:
            count = (status >> 9) & 0x7fffff
            data_buffer = self.pcap_first_buffer
            self.pcap_first_buffer = self.pcap_second_buffer
            self.pcap_second_buffer = self.get_next_pcap_buffer()
            self.pcap_data.extend(
                self.test.pcap_memory.mem[data_buffer:data_buffer + count * 4])
            await self.test.reg_write(
                '*DRV.PCAP_DMA_ADDR', self.pcap_second_buffer)

    async def handle_table_irq(self):
        self.log.debug('Handling TABLE IRQ')
        # TODO: implement table queuing
        #status = await self.test.reg_read('*REG.TABLE_IRQ_STATUS')
        #self.log.debug('TABLE IRQ STATUS: %X', status)

    def get_next_pcap_buffer(self):
        buffer = self.pcap_next_buffer
        self.pcap_next_buffer += self.pcap_buffer_size
        if self.pcap_next_buffer >= self.pcap_mem_size:
            self.pcap_next_buffer = 0

        return buffer

    async def run(self):
        self.wait_client()
        cocotb.start_soon(Clock(self.clock, 1, 'ns').start(start_high=False))
        want_quit = False
        # Wait a couple clock cycles to let the DUT initialize
        await ClockCycles(self.clock, 2)
        while not want_quit:
            irqs = await self.test.wait_for_irq(
                timeout=self.ticks_per_iteration)
            if irqs & 1:
                await self.handle_pcap_irq()
            if irqs & 2:
                await self.handle_table_irq()
            try:
                want_quit = await self.process_client()
            except BlockingIOError:
                pass

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
