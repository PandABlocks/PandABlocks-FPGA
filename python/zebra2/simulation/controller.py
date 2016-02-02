import time
import bisect
from collections import deque

import numpy as np

from .block import Block


# FPGA clock tick in seconds
CLOCK_TICK = 1.0 / 125e6

# These are the powers of two in an array
POW_TWO = 2 ** np.arange(32)



class Controller(object):

    def __init__(self, config_dir):
        Block.load_config(config_dir)
        # Lookup from (block_num, num, reg) -> (Block instance, attr_name)
        self.lookup = {}
        for name, config_block in Block.parser.blocks.items():
            if not name.startswith("*"):
                self._create_block(name, config_block)
        # Now divert the *REG registers to PCAP or ourself
        reg_config = Block.parser.blocks["*REG"]
        for attr_name, (reg, field) in reg_config.registers.items():
            if attr_name.startswith("PCAP_"):
                attr_name = attr_name[len("PCAP_"):]
                block = self.pcap
            else:
                block = self
            self.lookup[(reg_config.base, 0, reg)] = (block, attr_name)
        # Slow control always complete
        self.SLOW_REGISTER_STATUS = 0
        # When did we start
        self.start_time = time.time()
        # When do our blocks next need to be woken up?
        # List of (int ts, Block block)
        self.wakeups = []
        # What blocks are listening to each bit_bus and pos_bus parameter?
        # Dict of str bus_name -> [Block block]
        self.listeners = {}

    def _create_block(self, name, config_block):
        """Create an instance of the block if we can, or a Block if we can't

        Args:
            name (str): The name of the block (E.g. PCAP)
            config_block (ConfigBlock): ConfigBlock instance to configure it
        """
        # check if we have a block of the right type
        try:
            imp = __import__("zebra2.simulation." + name.lower())
            package = getattr(imp.simulation, name.lower())
            clsnames = [n for n in dir(package) if n.upper() == name]
            cls = getattr(package, clsnames[0])
            print "Got %s sim" % cls.__name__
        except ImportError:
            print "No %s sim, using Block" % name.title()

            class cls(Block):
                pass
            cls.__name__ = name.title()

        # Make instances of it
        for i in range(config_block.num):
            inst = cls()
            for attr_name, (reg, field) in config_block.registers.items():
                self.lookup[(config_block.base, i, reg)] = (inst, attr_name)
                if field.cls == "table" and field.reg[0] == "long":
                    # Long tables need a special entry
                    self.lookup[(config_block.base, i, -1)] = (inst,
                                                               "TABLE_DATA")
        # Store PCAP
        if name == "PCAP":
            self.pcap = inst
            inst.tick_data = False


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
            print 'Unknown read register', block_num, num, reg
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
            print 'Unknown write register', block_num, num, reg
        else:
            if block == self:
                if name == "BIT_READ_RST":
                    self.capture_bit_bus()
                elif name == "POS_READ_RST":
                    self.capture_pos_bus()
            else:
                field = block.config_block.fields.get(name, None)
                if field and field.typ.endswith("_mux"):
                    block_changes = self.update_listeners(block, name, value)
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
            print 'Unknown table register', block_num, num
        else:
            # Send data to long table data attribute of block
            block_changes = {block: {name: data}}
            self.do_tick(block_changes)

    def do_read_capture(self, max_length):
        """Read the capture data array from self.pcap

        Args:
            max_length (int): Max number of int32 words to read
        """
        if self.pcap.buf_len > 0:
            data_length = min(self.pcap.buf_len, max_length)
            result = +self.pcap.buf[:data_length]
            self.pcap.buf[:self.pcap.buf_len - data_length] = \
                self.pcap.buf[data_length:self.pcap.buf_len]
            self.pcap.buf_len -= data_length
            return result
        elif self.pcap.ACTIVE:
            # Return empty array if there's no data but we're still active
            return self.pcap.buf[:0]
        else:
            # Return None to indicate end of data capture stream
            return None

    def do_tick(self, block_changes=None):
        """Tick the simulation given the block and changes, or None

        Args:
            block (Block): Optional Block instance that needs input
            changes (dict): map str name -> int value of attrs that have changed
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
        while True:
            wake_ts, wake_block, wake_changes = self.wakeups[0]
            if ts == wake_ts:
                block_changes.setdefault(wake_block, wake_changes)
                self.wakeups.pop(0)
            else:
                break
        # Wake the selected blocks up
        if block_changes:
            new_wakeups = []
            for block, changes in block_changes.items():
                next_ts = block.on_changes(ts, changes)
                # Update bit_bus and pos_bus
                for attr, val in block._changes.items():
                    bus_name = "%s.%s" % (block.block_name, attr)
                    if bus_name in Block.parser.bit_bus:
                        idx = Block.parser.bit_bus[bus_name]
                        Block.bit_bus[idx] = val
                        Block.bit_changes[idx] = 1
                    elif bus_name in Block.parser.pos_bus:
                        idx = Block.parser.pos_bus[bus_name]
                        Block.pos_bus[idx] = val
                        Block.pos_changes[idx] = 1
                    # If someone's listening, tell them about it
                    for lblock, lattr in self.listeners.get(bus_name, ()):
                        new_wakeups.append((lblock, ts+1, {lattr: val}))
                # Tell us when we're next due to be woken
                if next_ts is not None:
                    new_wakeups.append(block, next_ts, {})
            # Insert all the new_wakeups into the table
            for item in new_wakeups:
                index = bisect.bisect(self.wakeups, item)
                self.wakeups.insert(index, item)

    def calc_timeout(self):
        """Calculate how long before the next wakeup is due

        Returns:
            int: The time before next wakeup, can also be negative or None
        """
        if self.wakeups:
            next_time = self.wakeups[0][0] * CLOCK_TICK + self.start_time
            return next_time - time.time()


    def update_listeners(self, block, name, value):
        """Update listeners for muxes on block

        Args:
            block (Block): Block that is updating an attr value
            name (str): Attribute name that is changin
            value (int): New value

        Returns:
            dict: map block -> {name: value} to be passed as block_changes
        """
        # Remove any old listener entries
        for listeners in self.listeners.values():
            try:
                listeners.remove((block, name))
            except ValueError:
                pass
        # get field info
        field = block.fields[name]
        # check old values
        if field.typ == "bit_mux":
            old_idx = Block.parser.bit_bus[getattr(block, name)]
            old_bus_val = Block.bit_bus[old_idx]
            new_bus_val = Block.bit_bus[value]
            bus_name = Block.parser.bit_bus[value]
        else:
            old_idx = Block.parser.pos_bus[getattr(block, name)]
            old_bus_val = Block.pos_bus[old_idx]
            new_bus_val = Block.pos_bus[value]
            bus_name = Block.parser.pos_bus[value]
        # Update listeners for this field
        self.listeners.setdefault(bus_name, []).append((block, name))
        # Generate changes
        if old_bus_val != new_bus_val:
            return {block: {name: new_bus_val}}


    def capture_bit_bus(self):
        """Capture bit bus so BIT_READ_VALUE can use it"""
        self._bit_read_data = deque()
        for i in range(4):
            # Pack bits from bit_bus into 32-bit number and add it to list
            vals = np.dot(self.bit_bus[i*32:(i+1)*32], POW_TWO)
            self._bit_read_data.append(vals)
            # Do the same for the change bits
            change = np.dot(self.bit_changes[i*32:(i+1)*32], POW_TWO)
            self._bit_read_data.append(change)

    @property
    def BIT_READ_VALUE(self):
        return self._bit_read_data.popleft()

    def capture_pos_bus(self):
        """Capture pos bus so POS_READ_VALUE and POS_READ_CHANGES can read it"""
        self._pos_read_data = deque(self.pos_bus)
        self.POS_READ_CHANGES = np.dot(self.pos_changes, POW_TWO)

    @property
    def POS_READ_VALUE(self):
        return self._pos_read_data.popleft()

