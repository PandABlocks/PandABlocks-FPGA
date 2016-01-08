from .task import Task
from .block import Block
from .event import Event

import time
import bisect

CLOCK_TICK = 1.0 / 125e6


class Zebra2(Task):
    def __init__(self, config_dir):
        Block.load_config(config_dir)
        super(Zebra2, self).__init__()

    def setup_event_loop(self):
        # When did we start
        self.start_time = time.time()
        # When do our blocks next need to be woken up
        self.wakeups = []
        # this is our bit bus and people listening to it
        self.bit_bus = []
        self.bit_changed = {}
        self.bit_listeners = []
        for i in range(128):
            self.bit_bus.append(0)
            self.bit_listeners.append([])
        # and the same for positions
        self.pos_bus = []
        self.pos_changed = {}
        self.pos_listeners = []
        for i in range(32):
            self.pos_bus.append(0)
            self.pos_listeners.append([])
        # Dict (name, i) -> Block()
        self.blocks = {}
        for name, config in Block.config.items():
            # check if we have a block of the right type
            try:
                imp = __import__("sim_zebra2." + name.lower())
                package = getattr(imp, name.lower())
                clsnames = [n for n in dir(package) if n.upper() == name]
                cls = getattr(package, clsnames[0])
                print "Got %s sim" % cls.__name__
            except ImportError:
                print "No %s sim, using Block" % name.title()

                class cls(Block):
                    pass
                cls.__name__ = name.title()
            # Make an instance of it
            for i in range(config.num):
                inst = cls(i+1)
                self.blocks[(inst.reg_base, i)] = inst
        # update specials
        #bit_zero = self.blocks[("BITS", 0)].ZERO
        bits_base = Block.registers["BITS"].base
        bit_one = self.blocks[(bits_base, 0)].ONE
        #pos_zero = self.blocks[("POSITIONS", 0).ZERO]
        self.bit_bus[bit_one] = 1

    def handle_events(self):
        if self.wakeups:
            # This is our next scheduled wakeup
            ts, block = self.wakeups[0]
            next_time = self.start_time + ts * CLOCK_TICK
            timeout = next_time - time.time()
        else:
            # No activity, wait for something to come in
            timeout = None
        # wait for a register set
        reg_data = None
        if timeout is None or timeout > 0:
            reg_data = self.get_next_event(timeout)
        # If we got a register set, process that
        if reg_data:
            (block, num, reg, value), done = reg_data
            # calculate FPGA timestamp from current time
            diff = time.time() - self.start_time
            ts = int(diff / CLOCK_TICK)
            # lookup block object and reg name
            block = self.blocks[(block, num)]
            name = block.regs[reg]
            # make an event with the register set
            event = Event(ts, reg={name: value})
            # if the event changes a mux then update listeners
            field = block.fields[name]
            if field.typ.endswith("_mux"):
                self.update_mux(block, event)
            elif field.cls == "time":
                # update value by masking bits
                if block.time_lohi[reg] == "lo":
                    hi = getattr(block, name) & 0xFFFF00000000
                    value = value + hi
                else:
                    lo = getattr(block, name) & 0xFFFFFFFF
                    value = (value << 32) + lo
                event.reg[name] = value
            self.process_blocks(ts, [(block, event)])
            done.set()
        elif self.wakeups:
            # just process the block that needs it
            ts, block = self.wakeups.pop(0)
            self.process_blocks(ts, [(block, Event(ts))])

    def update_mux(self, block, event):
        # remove block from all listeners
        for listeners in self.bit_listeners + self.pos_listeners:
            try:
                listeners.remove(block)
            except ValueError:
                pass
        # get field info
        name, value = event.reg.items()[0]
        field = block.fields[name]
        # check if the change would generate an event
        if field.typ == "bit_mux":
            if self.bit_bus[getattr(block, name)] != self.bit_bus[value]:
                event.bit[value] = self.bit_bus[value]
        else:
            if self.pos_bus[getattr(block, name)] != self.pos_bus[value]:
                event.pos[value] = self.pos_bus[value]
        # update listeners for this block
        for fname, field in block.fields.items():
            if fname == name:
                fvalue = value
            else:
                fvalue = getattr(block, fname, None)
            if field.typ == "bit_mux":
                self.bit_listeners[fvalue].append(block)
            if field.typ == "pos_mux":
                self.pos_listeners[fvalue].append(block)

    def process_blocks(self, ts, blocks_events):
        while True:
            # work out what bus updates happen as a result of these events
            bit_updates = {}
            pos_updates = {}
            block_wakeups = {}
            for block, event in blocks_events:
                next_event = block.on_event(event)
                if next_event.ts is not None:
                    block_wakeups[block] = next_event.ts
                bit_updates.update(next_event.bit)
                pos_updates.update(next_event.pos)
            for i, val in bit_updates.items():
                if self.bit_bus[i] != val:
                    self.bit_bus[i] = val
                    self.bit_changed[i] = 1
            for i, val in pos_updates.items():
                if self.pos_bus[i] != val:
                    self.pos_bus[i] = val
                    self.pos_changed[i] = 1
            # dict block->event
            events = {}
            # make events for things that appear immediately
            for index, value in bit_updates.items():
                listeners = self.bit_listeners[index]
                for block in listeners:
                    event = events.setdefault(block, Event(ts+1))
                    event.bit[index] = value
            for index, value in pos_updates.items():
                listeners = self.pos_listeners[index]
                for block in listeners:
                    event = events.setdefault(block, Event(ts+1))
                    event.pos[index] = value
            # now delete wakeups for these things
            for block in events:
                block_wakeups.pop(block, None)
            # insert all other wakeups into the table
            for block, ts in block_wakeups.items():
                index = bisect.bisect(self.wakeups, (ts, block))
                self.wakeups.insert(index, (ts, block))
            # recurse if needed
            if events:
                blocks_events = events.items()
            else:
                return
