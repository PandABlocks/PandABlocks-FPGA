#!/usr/bin/env python

from cocotb.triggers import RisingEdge
from cocotb_bus_mini import Bus
from cocotb_bus_mini import BusMonitor
import logging


class AxiLiteMaster(object):
    def __init__(self, dut, name, clock):
        self.dut = dut
        self.clock = clock
        self.bus = Bus(dut, name, signals=[
            'awaddr', 'awprot', 'awvalid', 'awready',
            'wdata', 'wstrb', 'wvalid', 'wready',
            'bresp', 'bvalid', 'bready',
            'araddr', 'arprot', 'arvalid', 'arready',
            'rdata', 'rresp', 'rvalid', 'rready',
        ])
        self.init_signals()

    def init_signals(self):
        self.bus.awaddr.value = 0
        self.bus.awprot.value = 0
        self.bus.awvalid.value = 0
        self.bus.wdata.value = 0
        self.bus.wstrb.value = 0
        self.bus.wvalid.value = 0
        self.bus.bready.value = 0
        self.bus.araddr.value = 0
        self.bus.arprot.value = 0
        self.bus.arvalid.value = 0
        self.bus.rready.value = 0

    async def write(self, address, data):
        self.bus.awaddr.value = address
        self.bus.awprot.value = 0
        self.bus.awvalid.value = 1
        self.bus.wdata.value = data
        self.bus.wstrb.value = 0xF
        self.bus.wvalid.value = 1
        got_aw = False
        got_w = False
        while True:
            await RisingEdge(self.clock)
            if self.bus.awready.value == 1:
                self.bus.awvalid.value = 0
                got_aw = True
            if self.bus.wready.value == 1:
                self.bus.wvalid.value = 0
                got_w = True

            if got_aw and got_w:
                self.bus.bready.value = 1
                break

        while self.bus.bvalid.value == 0:
            await RisingEdge(self.clock)
        self.bus.bready.value = 0

    async def read(self, address):
        self.bus.araddr.value = address
        self.bus.arprot.value = 0
        self.bus.arvalid.value = 1
        while True:
            await RisingEdge(self.clock)
            if self.bus.arready.value == 1:
                self.bus.arvalid.value = 0
                self.bus.rready.value = 1
                break

        while self.bus.rvalid.value != 1:
            await RisingEdge(self.clock)

        data = self.bus.rdata.value.to_unsigned()
        self.bus.rready.value = 0
        await RisingEdge(self.clock)
        return data


class AxiWriteSlave(BusMonitor):
    # Simplifications:
    # - address should arrive before the last data beat
    # - strobe is always all-ones
    # - incremental burst is assumed
    _signals = [
        'awaddr',
        'awvalid',
        'awready',
        'wdata',
        'wstrb',
        'wvalid',
        'wready',
        'wlast',
        'bvalid',
        'bready',
        'bresp',
    ]

    def __init__(self, dut, name, clock, **kwargs):
        self.log = logging.getLogger(__class__.__name__)
        self.want_quit = False
        self.n_bursts = 0
        self.n_resp = 0
        super().__init__(dut, name, clock, **kwargs)
        self.init_signals()

    def init_signals(self):
        self.bus.awready.value = 0
        self.bus.wready.value = 0
        self.bus.bvalid.value = 0
        self.bus.bresp.value = 0

    async def _monitor_recv(self):
        self.bus.awready.value = 1
        self.bus.wready.value = 1
        data_list = []
        addr = None
        need_resp = 0
        while not self.want_quit:
            await RisingEdge(self.clock)
            if self.bus.awvalid.value == 1 and self.bus.awready.value == 1:
                addr = self.bus.awaddr.value.to_unsigned()
                self.bus.awready.value = 0
                self.log.debug('AXI Write Slave received address 0x%08X', addr)

            if self.bus.wvalid.value == 1:
                data_list.append(self.bus.wdata.value.to_unsigned())
                if self.bus.wlast.value == 1:
                    self.log.debug(
                        'AXI Write Slave received burst of %d', len(data_list))
                    assert addr is not None, \
                        'Address should be set before last data beat'
                    self._recv((addr, data_list))
                    data_list = []
                    addr = None
                    need_resp += 1
                    self.n_bursts += 1
                    self.bus.awready.value = 1

            self.bus.bvalid.value = 1 if need_resp else 0
            if self.bus.bvalid.value == 1 and self.bus.bready.value == 1:
                need_resp -= 1
                self.n_resp += 1
                if not need_resp:
                    self.bus.bvalid.value = 0


class AxiReadSlave(BusMonitor):
    # Simplifications:
    # - strobe is always all-ones
    _signals = [
        'araddr',
        'arvalid',
        'arready',
        'arlen',
        'rdata',
        'rresp',
        'rvalid',
        'rlast',
        'rready',
    ]

    def __init__(self, dut, name, clock, mem_read=None, **kwargs):
        self.log = logging.getLogger(__class__.__name__)
        self.want_quit = False
        self.n_bursts = 0
        self.n_resp = 0
        self.mem_read = mem_read
        super().__init__(dut, name, clock, **kwargs)
        self.init_signals()

    def init_signals(self):
        self.bus.arready.value = 0
        self.bus.rvalid.value = 0
        self.bus.rdata.value = 0
        self.bus.rresp.value = 0

    async def _monitor_recv(self):
        self.bus.arready.value = 1
        left = 0
        while not self.want_quit:
            await RisingEdge(self.clock)

            if self.bus.arvalid.value == 1 and self.bus.arready.value == 1:
                addr = self.bus.araddr.value.to_unsigned()
                self.bus.arready.value = 0
                self.log.debug('AXI Read Slave received address 0x%08X', addr)
                data = self.mem_read(addr) if self.mem_read else 0
                left = self.bus.arlen.value.to_unsigned()
                addr += 4
                self.bus.rdata.value = data
                self.bus.rvalid.value = 1
                self.bus.rlast.value = 1 if left == 0 else 0
                self.n_bursts += 1

            if self.bus.rvalid.value == 1 \
                    and self.bus.rready.value == 1:
                self.n_resp += 1
                if left:
                    data = self.mem_read(addr) if self.mem_read else 0
                    addr += 4
                    self.bus.rdata.value = data
                    left -= 1
                    if left == 0:
                        self.bus.rlast.value = 1

                if self.bus.rlast.value == 1:
                    self.bus.arready.value = 1
                    self.bus.rlast.value = 0
                    self.bus.rvalid.value = 0
