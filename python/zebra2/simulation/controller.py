import time
import bisect
from collections import deque

import numpy as np

from .block import Block


# FPGA clock tick in seconds
CLOCK_TICK = 1.0 / 125e6


class Controller(object):

    def __init__(self, config_dir):
        Block.load_config(config_dir)
        # Changesets
        self.bit_changes = np.zeros(128, dtype=np.bool_)
        self.pos_changes = np.zeros(32, dtype=np.bool_)
        # Lookup from (block_num, num, reg) -> (Block instance, attr_name)
        self.lookup = {}
        # Map (block, attr) -> bus, bus_changes, idx
        # Map ("bit"/"pos", idx) -> block, attr
        self.bus_lookup = {}
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
        # List of (int ts, Block block, dict changes)
        self.wakeups = []
        # These are the next wakeup times for each block
        self.next_wakeup = {}
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
            cls.add_properties()

        # Make instances of it
        for i in range(config_block.num):
            inst = cls()
            for attr_name, (reg, field) in config_block.registers.items():
                self.lookup[(config_block.base, i, reg)] = (inst, attr_name)
                if field.cls == "table" and field.reg[0] == "long":
                    # Long tables need a special entry
                    entry = (inst, "TABLE_ADDR")
                    self.lookup[(config_block.base, i, -1)] = entry
            for attr_name, (indexes, field) in config_block.outputs.items():
                if field.cls == "pos_out":
                    bus, bus_changes = Block.pos_bus, self.pos_changes
                elif field.cls == "bit_out":
                    bus, bus_changes = Block.bit_bus, self.bit_changes
                else:
                    # ignore ext_out
                    continue
                idx = int(field.reg[i])
                self.bus_lookup[(inst, attr_name)] = (bus, bus_changes, idx)
                self.bus_lookup[(field.cls[:3], idx)] = (inst, attr_name)

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
        if block_changes:
            for block, changes in block_changes.items():
                next_ts = block.on_changes(ts, changes)
                # Update bit_bus and pos_bus
                for attr, val in getattr(block, "_changes", {}).items():
                    # Map (block, attr) -> bus, bus_changes, idx
                    # Map (bus, idx) -> block, attr
                    data = self.bus_lookup.get((block, attr), None)
                    if data is None:
                        continue
                    bus, bus_changes, idx = data
                    bus[idx] = val
                    bus_changes[idx] = 1
                    # If someone's listening, tell them about it
                    for lblock, lattr in self.listeners.get((block, attr), ()):
                        self.insert_wakeup(ts+1, lblock, {lattr: val})
                block._changes = {}
                # Remove the old wakeup if we have one
                self.remove_wakeup(block)
                # Tell us when we're next due to be woken
                if next_ts is not None:
                    self.insert_wakeup(next_ts, block, {})

    def insert_wakeup(self, ts, block, changes):
        item = (ts, block, changes)
        # Insert the new wakeup
        index = bisect.bisect(self.wakeups, item)
        self.wakeups.insert(index, item)
        self.next_wakeup[block] = ts

    def remove_wakeup(self, block):
        # Delete the old entry
        old_ts = self.next_wakeup.get(block, None)
        if old_ts is not None:
            index = bisect.bisect(self.wakeups, (old_ts, None, None))
            while True:
                wakeup = self.wakeups[index]
                assert wakeup[0] == old_ts, \
                    "Gone too far %d > %d" % (wakeup[0], old_ts)
                if wakeup[1] == block:
                    self.wakeups.pop(index)
                    self.next_wakeup[block] = None
                    return

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
        field = block.config_block.fields[name]
        # check old values
        old_bus_val = getattr(block, name)
        if field.typ == "bit_mux":
            new_bus_val = Block.bit_bus[value]
        else:
            new_bus_val = Block.pos_bus[value]
        lblock, lattr = self.bus_lookup[(field.typ[:3], value)]
        # Update listeners for this field
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
            tmp_bits[16:] = Block.bit_bus[i*16:(i+1)*16]
            # Bottom half is bit changes
            tmp_bits[:16] = self.bit_changes[i*16:(i+1)*16]
            vals = Block.bits_to_int(tmp_bits)
            self._bit_read_data.append(vals)
        self.bit_changes.fill(0)

    @property
    def BIT_READ_VALUE(self):
        return int(self._bit_read_data.popleft())

    def capture_pos_bus(self):
        """Capture pos bus so POS_READ_VALUE and POS_READ_CHANGES can read it"""
        self._pos_read_data = deque(Block.pos_bus)
        self.POS_READ_CHANGES = int(Block.bits_to_int(self.pos_changes))
        self.pos_changes.fill(0)

    @property
    def POS_READ_VALUE(self):
        return int(self._pos_read_data.popleft())
