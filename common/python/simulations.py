from __future__ import print_function
import socket
import select
import struct
import time
import bisect
import imp
import os
import sys
from collections import namedtuple, deque

import numpy as np

from .configs import BlockConfig, RegisterCounter, make_getter_setter
from .compat import TYPE_CHECKING, add_metaclass

if TYPE_CHECKING:
    from typing import List, Dict, Tuple, Any

# These are the powers of two in an array
POW_TWO = 2 ** np.arange(32, dtype=np.uint32)
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")

# FPGA clock tick in seconds
CLOCK_TICK = 1.0 / 125e6


# We daemonise the server by double forking, but we leave the controlling
# terminal and other file connections alone.
def daemonise():
    if os.fork():
        # Exit first parent
        sys.exit(0)
    # Do second fork to avoid generating zombies
    if os.fork():
        sys.exit(0)


def properties_from_ini(src_path, ini_name=None):
    # type: (str, str) -> Tuple[Any, List[property]]
    if ini_name is None:
        # Only given src_path, calculate ini_path and ini_name from it
        ini_name = os.path.basename(src_path)
        ini_path = src_path
    else:
        # Given both, ini_name is in the same dir as src_path
        ini_path = os.path.join(os.path.dirname(src_path), ini_name)
    assert ini_name.endswith(".block.ini"), \
        "Expected <block>.block.ini, got %s" % ini_name
    block_name = ini_name[:-len(".block.ini")]
    properties = []
    names = []
    block_config = BlockConfig(block_name.upper(), "soft", 1, ini_path)
    block_config.register_addresses(RegisterCounter())
    for field in block_config.fields:
        for config in field.registers + field.bus_entries:
            # Delay register swallowed by wrapper, so don't expose to simulation
            if not config.name.endswith("_DLY"):
                names.append(config.name)
                prop = property(*make_getter_setter(config))
                properties.append(prop)

    # Create an object BlockNames with attributes FIELD1="FIELD1", F2="F2", ...
    names = namedtuple("%sNames" % block_name.title(), names)(*names)
    return names, properties


class BlockSimulationMeta(type):
    """Metaclass to make sure all field names are bound to the correct
    instance attribute names"""
    def __new__(cls, clsname, bases, dct):
        for name, val in dct.items():
            if isinstance(val, property):
                config = getattr(val.fget, "config")
                if config:
                    assert name == config.name, \
                        "Property %s mismatch with Config name %s" % (
                            name, config.name)
        return super(BlockSimulationMeta, cls).__new__(cls, clsname, bases, dct)


@add_metaclass(BlockSimulationMeta)
class BlockSimulation(object):
    bit_bus = np.zeros(128, dtype=np.bool_)
    pos_bus = np.zeros(32, dtype=np.int32)
    pos_change = []
    #: This will be dictionary with changes pushed by any properties created
    #: with properties_from_ini()
    changes = None

    @classmethod
    def bits_to_int(cls, bits):
        """Convert 32 element bit array into an int number"""
        return np.dot(bits, POW_TWO)

    def on_changes(self, ts, changes):
        """Handle field changes at a particular timestamp

        Args:
            ts (int): The timestamp the changes occurred at
            changes (dict): Field names that changed with their integer value

        Returns:
             If the Block needs to be called back at a particular ts then return
             that int, otherwise return None and it will be called when a field
             next changes
        """
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)


class SocketFail(Exception):
    pass


class SimulationServer(object):

    """Simulation server exposing PandA simulation controller to TCP server"""

    def __init__(self, controller):
        """Start simulation server and create controller

        Args:
            controller(Controller): Zebra2 controller object
        """
        self.controller = controller
        self.sock_l = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock_l.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock_l.bind(('localhost', 9999))
        self.sock_l.listen(0)
        # The socket we will create on run()
        self.sock = None

    def run(self):
        """Accept the first connection to server, then start simulation"""
        (self.sock, addr) = self.sock_l.accept()
        self.sock_l.close()

        # Set no delay on this as we're only looking at tiny amounts of data
        self.sock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        # Now start ticking the simulation
        try:
            while True:
                timeout = self.controller.calc_timeout()
                # wait for up to timeout for some data
                # timeout can be negative!
                (rlist, _, _) = select.select((self.sock,), (), (), timeout)
                # If we got a response, service it
                if rlist:
                    self._respond()
                # Now service the controller
                self.controller.do_tick()
        except (KeyboardInterrupt, SocketFail) as e:
            print("Simulation closed: %r" % e)

    def _read(self, n):
        """Blocking read n bytes from socket and return them"""
        result = ''
        while len(result) < n:
            rx = self.sock.recv(n - len(result))
            if not rx:
                raise SocketFail('End of input')
            result = result + rx
        return result

    def _respond(self):
        """Read a command from the socket and respond to it"""
        command_word = self._read(4)
        command, block, num, reg = struct.unpack('cBBB', command_word)
        if command == 'R':
            # Read one register
            tx = self.controller.do_read_register(block, num, reg)
            self.sock.sendall(struct.pack('I', tx))
        elif command == 'W':
            # Write one register
            value, = struct.unpack('I', self._read(4))
            self.controller.do_write_register(block, num, reg, value)
        elif command == 'T':
            # Write data array to large table
            length, = struct.unpack('I', self._read(4))
            data = self._read(length * 4)
            data = np.fromstring(data, dtype=np.int32)
            self.controller.do_write_table(block, num, data)
        elif command == 'D':
            # Retrieve increment of data stream
            length, = struct.unpack('I', self._read(4))
            data = self.controller.do_read_capture(length / 4)
            if data is None:
                self.sock.sendall(struct.pack('i', -1))
            else:
                assert data.dtype == np.int32
                raw_data = data.data
                assert len(raw_data) <= length
                self.sock.sendall(struct.pack('I', len(raw_data)))
                self.sock.sendall(raw_data)
        else:
            print('Unexpected command', repr(command_word))
            raise SocketFail('Unexpected command')


class SimulationController(object):

    def __init__(self, verbose):
        self.verbose = verbose
        # Changesets
        self.bit_changes = np.zeros(128, dtype=np.bool_)
        self.pos_changes = np.zeros(32, dtype=np.bool_)
        # Lookup from (block_num, num, reg) -> (Block instance, attr_name)
        self.lookup = {}  # type: Dict[Tuple[int, int, int], Tuple[object, str]]
        # Map (block, attr) -> bus, bus_changes, idx
        # Map ("bit"/"pos", idx) -> block, attr
        self.bus_lookup = {}
        # Bus names for each mux
        # {(block, attr):"bit"/"pos"}
        self.bus_muxes = {}
        # Now divert the *REG registers to us
        self.lookup[(0, 0, 0)] = (self, "FPGA_VERSION")
        self.FPGA_VERSION = 0x111
        self.lookup[(0, 0, 1)] = (self, "FPGA_BUILD")
        self.FPGA_BUILD = 0x222
        self.lookup[(0, 0, 2)] = (self, "USER_VERSION")
        self.USER_VERSION = 0x333
        self.lookup[(0, 0, 3)] = (self, "BIT_READ_RST")
        self.lookup[(0, 0, 4)] = (self, "BIT_READ_VALUE")
        self.lookup[(0, 0, 5)] = (self, "POS_READ_RST")
        self.lookup[(0, 0, 6)] = (self, "POS_READ_VALUE")
        self.lookup[(0, 0, 7)] = (self, "POS_READ_CHANGES")
        # When did we start
        self.start_time = time.time()
        # When do our blocks next need to be woken up?
        # List of (int ts, Block block, dict changes)
        self.wakeups = []
        # These are the next wakeup times for each block
        self.next_wakeup = {}
        # What blocks are listening to each bit_bus and pos_bus parameter?
        # {(block, attr_name): [(block, attr_name)]}
        self.listeners = {}
        # What delay should each bit_mux have
        # Dict of (Block block, str attr) -> int dly
        self.delays = {}
        # The pcap Block
        self.pcap = None
        # Start from base register 2 to allow for *REG and *DRV spaces
        self.counters = RegisterCounter(block_count=2)

    def create_block(self, ini_path, number, block_address):
        """Create an instance of the block if we can, or a Block if we can't

        Args:
            ini_path (str): The path to the .block.ini file, relative to TOP
            number (int): The number of instances Blocks that will be created,
                like 8
            block_address (int): The Block section of the register address space
        """
        block_name = os.path.basename(ini_path).replace(".block.ini", "")
        block_config = BlockConfig(block_name.upper(), "soft", number, ini_path)
        block_config.register_addresses(self.counters)
        assert block_address == block_config.block_address
        ini_path = os.path.join(ROOT, ini_path)
        module_path = os.path.dirname(ini_path)
        try:
            f, pathname, description = imp.find_module(
                block_name + "_sim", [module_path])
            package = imp.load_module(
                block_name + "_sim", f, pathname, description)
            clsnames = [n for n in dir(package)
                        if n.lower() == block_name + "simulation"]
            cls = getattr(package, clsnames[0])
            print("Got %s sim" % cls.__name__)
        except ImportError:
            print("No %s sim, using BlockSimulation" % block_name.title())

            class cls(BlockSimulation):
                pass
            cls.__name__ = block_name.title() + "Simulation"
            for name, prop in zip(*properties_from_ini(ini_path)):
                setattr(cls, name, prop)

        # Make instances of it
        for i in range(number):
            inst = cls()
            inst.changes = {}
            for field in block_config.fields:
                # If it's a mux, add it to the list
                if field.type.endswith("_mux"):
                    self.bus_muxes[(inst, field.name)] = field.type[:-4]
                for register in field.registers:
                    # Delays handled differently
                    if register.name.endswith("_DLY"):
                        self.delays[(inst, register.name)] = 0
                    self.lookup[(block_address, i, register.number)] = (
                            inst, register.name)
                if field.bus_entries:
                    bus_entry = field.bus_entries[i]
                    if bus_entry.bus == "pos":
                        bus, bus_changes = cls.pos_bus, self.pos_changes
                    elif bus_entry.bus == "bit":
                        bus, bus_changes = cls.bit_bus, self.bit_changes
                    else:
                        # ignore ext_out
                        continue
                    # Rely on the fact that pos_out and bit_out both produce
                    # only one entry per block instance
                    assert len(field.bus_entries) == number, \
                        "%s.%s doesn't have %d bus entries, it has %d" % (
                            block_name, field.name, number,
                            len(field.bus_entries))
                    self.bus_lookup[(bus_entry.bus, bus_entry.index)] = (
                        inst, bus_entry.name)
                    self.bus_lookup[(inst, bus_entry.name)] = (
                        bus, bus_changes, bus_entry.index)

            # Store PCAP
            if block_name == "pcap":
                self.pcap = inst
                inst.tick_data = False
                # And divert the *REG PCAP registers to PCAP
                self.lookup[(0, 0, 8)] = (self.pcap, "PCAP_START_WRITE")
                self.lookup[(0, 0, 9)] = (self.pcap, "PCAP_WRITE")
                self.lookup[(0, 0, 10)] = (self.pcap, "PCAP_ARM")
                self.lookup[(0, 0, 11)] = (self.pcap, "PCAP_DISARM")

    def do_read_register(self, block_num, num, reg):
        """Read the register value for a given block and register number

        Args:
            block_num (int): The register base for the block
            num (int): The instance number of the block (from 0..maxnum-1)
            reg (int): The field register offset for the block

        Returns:
            int: The value of the register
        """
        try:
            block, name = self.lookup[(block_num, num, reg)]
        except KeyError:
            print('Unknown read register', block_num, num, reg)
            value = 0
        else:
            value = getattr(block, name)
        return value

    def do_write_register(self, block_num, num, reg, value):
        """Write the register value for a given block and register number

        Args:
            block_num (int): The register base for the block
            num (int): The instance number of the block (from 0..maxnum-1)
            reg (int): The field register offset for the block
            value (int): The value to write
        """
        try:
            block, name = self.lookup[(block_num, num, reg)]
        except KeyError:
            print('Unknown write register', block_num, num, reg)
        else:
            if block == self:
                if name == "BIT_READ_RST":
                    self.capture_bit_bus()
                elif name == "POS_READ_RST":
                    self.capture_pos_bus()
                else:
                    print('Not writing register %s to %s' % (name, value))
            else:
                if self.verbose:
                    print("Write %s[%d].%s=%s" % (
                        block.__class__.__name__, num, name, value))
                if (block, name) in self.delays:
                    # Note: this is different from the FPGA implementation
                    block_changes = {}
                    self.delays[(block, name)] = value
                elif (block, name) in self.bus_muxes:
                    bus = self.bus_muxes[(block, name)]
                    block_changes = self.update_mux(block, name, value, bus)
                else:
                    block_changes = {block: {name: value}}
                self.do_tick(block_changes)

    def do_write_table(self, block_num, num, data):
        """Write a table value for a given block and register number

        Args:
            block_num (int): The register base for the block
            num (int): The instance number of the block (from 0..maxnum-1)
            data (numpy.ndarray): The data to write
        """
        try:
            block, name = self.lookup[(block_num, num, -1)]
        except KeyError:
            print('Unknown table register', block_num, num)
        else:
            # Send data to long table data attribute of block
            block_changes = {block: {name: data}}
            self.do_tick(block_changes)

    def do_read_capture(self, max_length):
        """Read the capture data array from self.pcap

        Args:
            max_length (int): Max number of int32 words to read
        """
        return self.pcap.read_data(max_length)

    def do_tick(self, block_changes=None):
        """Tick the simulation given the block and changes, or None

        Args:
            block_changes (dict): map str name -> int value of attrs that have
                changed
        """
        ts = int((time.time() - self.start_time) / CLOCK_TICK)
        if block_changes is None:
            block_changes = {}
        # If we have a wakeup, then make sure we aren't going back in time
        if self.wakeups:
            wake_ts, _, _ = self.wakeups[0]
            if ts > wake_ts:
                ts = wake_ts
        # Keep adding blocks to be processed at this ts
        while self.wakeups:
            wake_ts, wake_block, wake_changes = self.wakeups[0]
            if ts == wake_ts:
                block_changes.setdefault(wake_block, wake_changes)
                self.wakeups.pop(0)
                self.next_wakeup[wake_block] = None
            else:
                break
        # Wake the selected blocks up
        new_wakeups = self.process_blocks(ts, block_changes)
        # Schedule the wakeups at the correct time
        for (block, wakeup), changes in new_wakeups.items():
            self.remove_wakeup(block)
            self.insert_wakeup(wakeup, block, changes)

    def process_blocks(self, ts, block_changes):
        # map block -> changes
        new_wakeups = {}
        pos_changes = []
        for block, changes in block_changes.items():
            # Remove the old wakeup if we have one
            self.remove_wakeup(block)
            next_ts = block.on_changes(ts, changes)
            # Update bit_bus and pos_bus
            for attr, val in block.changes.items():
                # Map (block, attr) -> bus, bus_changes, idx
                # Map (bus, idx) -> block, attr
                data = self.bus_lookup.get((block, attr), None)
                if data is None:
                    continue
                bus, bus_changes, idx = data
                if bus is BlockSimulation.pos_bus:
                    pos_changes.append(idx)
                bus[idx] = val
                bus_changes[idx] = 1
                # If someone's listening, tell them about it
                for lblock, lattr in self.listeners.get((block, attr), []):
                    # How long do they need to wait for an event
                    dly = self.delays.get((lblock, lattr), 0)
                    # Add it to our list of new wakeups for this block
                    key = (lblock, ts+1+dly)
                    new_wakeups.setdefault(key, {})[lattr] = val
            # Reset the changed attributes dict
            block.changes = {}
            # If we are due to be woken up, add this one to the wakeup dict
            if next_ts is not None:
                new_wakeups.setdefault((block, next_ts), {})
        if pos_changes:
            new_wakeups.setdefault((self.pcap, ts+1), {})["POS_BUS"] = \
                pos_changes
        return new_wakeups

    def insert_wakeup(self, ts, block, changes):
        assert block not in self.next_wakeup, \
            "Block %s already has a wakeup" % block
        item = (ts, block, changes)
        # Insert the new wakeup
        index = bisect.bisect(self.wakeups, item)
        self.wakeups.insert(index, item)
        self.next_wakeup[block] = ts

    def remove_wakeup(self, block):
        # Delete the old entry
        old_ts = self.next_wakeup.pop(block, None)
        if old_ts is not None:
            index = bisect.bisect(self.wakeups, (old_ts, None, None))
            while True:
                wakeup = self.wakeups[index]
                assert wakeup[0] == old_ts, \
                    "Gone too far %d > %d" % (wakeup[0], old_ts)
                if wakeup[1] == block:
                    assert wakeup[2] == {}, \
                        "Popping a wakeup with changes: %s" % wakeup
                    self.wakeups.pop(index)
                    return

    def calc_timeout(self):
        """Calculate how long before the next wakeup is due

        Returns:
            int: The time before next wakeup or zero if past or None if no
            wakeup set
        """
        if self.wakeups:
            next_time = self.wakeups[0][0] * CLOCK_TICK + self.start_time
            return max(0, next_time - time.time())

    def update_mux(self, block, name, value, bus):
        """Update listeners for muxes on block

        Args:
            block (Block): Block that is updating an attr value
            name (str): Attribute name that is changing
            value (int): New value
            bus (str): bit or pos

        Returns:
            dict: map block -> {name: value} to be passed as block_changes
        """
        # Remove any old listener entries
        for listeners in self.listeners.values():
            try:
                listeners.remove((block, name))
            except ValueError:
                pass
        # check old values
        old_bus_val = getattr(block, name)
        if bus == "bit":
            if value == 128:
                new_bus_val = 0
            elif value == 129:
                new_bus_val = 1
            else:
                new_bus_val = BlockSimulation.bit_bus[value]
        else:
            if value == 32:
                new_bus_val = 0
            else:
                new_bus_val = BlockSimulation.pos_bus[value]
        lblock, lattr = self.bus_lookup.get((bus, value), (None, None))
        if lblock:
            # This comes from a block rather than being a constant, so add
            # ourself to the listeners for this field
            self.listeners.setdefault((lblock, lattr), []).append((block, name))
        # Generate changes
        if old_bus_val != new_bus_val:
            return {block: {name: new_bus_val}}

    def capture_bit_bus(self):
        """Capture bit bus so BIT_READ_VALUE can use it"""
        self._bit_read_data = deque()
        tmp_bits = np.empty(32, dtype=np.bool_)
        for i in range(8):
            # Pack bits from bit_bus into 32-bit number and add it to list
            # Top half is bit bus
            tmp_bits[16:] = BlockSimulation.bit_bus[i*16:(i+1)*16]
            # Bottom half is bit changes
            tmp_bits[:16] = self.bit_changes[i*16:(i+1)*16]
            vals = BlockSimulation.bits_to_int(tmp_bits)
            self._bit_read_data.append(vals)
        self.bit_changes.fill(0)

    @property
    def BIT_READ_VALUE(self):
        return int(self._bit_read_data.popleft())

    def capture_pos_bus(self):
        """Capture pos bus so POS_READ_VALUE and POS_READ_CHANGES can read it"""
        self._pos_read_data = deque(BlockSimulation.pos_bus)
        self.POS_READ_CHANGES = int(BlockSimulation.bits_to_int(self.pos_changes))
        self.pos_changes.fill(0)

    @property
    def POS_READ_VALUE(self):
        return int(self._pos_read_data.popleft())
