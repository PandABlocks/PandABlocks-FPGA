from collections import deque

import numpy as np

from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING


# This is the max size of internal buffer of captured data before being shipped
# off
MAX_BUFFER = 1 << 16

# Modes for CaptureEntry
VALUE = 0
DIFFERENCE = 1
SUM_L = 2
SUM_H = 3
MIN = 4
MAX = 5

# Enums for HEALTH
OK = 0
TOO_CLOSE = 1
SAMPLES_OVERFLOW = 2

NAMES, PROPERTIES = properties_from_ini(__file__, "pcap.block.ini")


class CaptureEntry(object):
    """Corresponds to a request to capture one part of the pos bus in a
    particular mode, like INENC1.VAL MIN"""

    def __init__(self, idx):
        self.idx = idx

    @property
    def value(self):
        return BlockSimulation.pos_bus[self.idx]

    def on_rising_gate(self, ts):
        """Rising gate or if gate is high at enable"""
        pass

    def on_falling_gate(self, ts):
        """Falling gate or if gate is low at disable"""
        pass

    def on_gated_value(self, ts):
        """Called when value is changed with current gate"""
        pass

    def on_capture(self, ts, gate):
        """Handle a rising edge of CAPTURE with ts relative to enable"""
        if gate:
            # Gate was high, so act as if we had a falling then rising edge
            self.on_falling_gate(ts)
        for y in self.yield_data():
            yield y
        if gate:
            self.on_rising_gate(ts)

    def yield_data(self):
        """Called immediately after on_capture

        Yields:
            int: The 32-bit int to store
        """
        return iter(())

    @classmethod
    def find_existing(cls, l):
        return [x for x in l if isinstance(x, cls)]

    @classmethod
    def create_if_not_existing(cls, l, *args):
        existing = cls.find_existing(l)
        if existing:
            assert len(existing) == 1, "Expected one, got %s" % (l,)
            return existing[0]
        else:
            return cls(*args)

    @classmethod
    def definitely_create(cls, l, *args):
        assert not cls.find_existing(l), "%s already defined in %s" % (cls, l)
        return cls(*args)


class ValueCaptureEntry(CaptureEntry):
    def on_capture(self, ts, gate):
        # Just yield the current value
        yield self.value


class DifferenceCaptureEntry(CaptureEntry):
    value_at_rising = None  # value when gate rising
    data = 0  # sum of differences while gate high

    def on_rising_gate(self, ts):
        self.value_at_rising = self.value

    def on_falling_gate(self, ts):
        # add the difference during this gate
        self.data += (self.value - self.value_at_rising)

    def yield_data(self):
        yield self.data
        self.data = 0


class SumCaptureEntry(CaptureEntry):
    data = 0  # sum of all values while gate is high
    prev_value = 0  # last value we latched
    prev_ts = 0  # last ts we latched it at
    lo = False
    hi = False

    def __init__(self, idx, shift):
        super(SumCaptureEntry, self).__init__(idx)
        self.shift = shift

    def latch_value(self, ts):
        self.prev_ts = ts
        self.prev_value = self.value

    def on_rising_gate(self, ts):
        self.latch_value(ts)

    def on_falling_gate(self, ts):
        # Add in what we have
        self.data += (ts - self.prev_ts) * self.prev_value

    def on_gated_value(self, ts):
        # Add all the entries into the sum
        self.data += (ts - self.prev_ts) * self.prev_value
        self.latch_value(ts)

    def yield_data(self):
        data = self.data >> self.shift
        # Yield low then high
        if self.lo:
            yield data & (2 ** 32 - 1)
        if self.hi:
            yield data >> 32
        self.data = 0


class MinCaptureEntry(CaptureEntry):
    INT32_MAX = np.iinfo(np.int32).max
    data = INT32_MAX

    def on_rising_gate(self, ts):
        self.data = min(self.data, self.value)

    def on_gated_value(self, ts):
        self.data = min(self.data, self.value)

    def yield_data(self):
        yield self.data
        self.data = self.INT32_MAX


class MaxCaptureEntry(CaptureEntry):
    INT32_MIN = np.iinfo(np.int32).min
    data = INT32_MIN

    def on_rising_gate(self, ts):
        self.data = max(self.data, self.value)

    def on_gated_value(self, ts):
        self.data = max(self.data, self.value)

    def yield_data(self):
        yield self.data
        self.data = self.INT32_MIN


class TsStartCaptureEntry(CaptureEntry):
    data = -1
    lo = False
    hi = False

    def on_rising_gate(self, ts):
        if self.data == -1:
            self.data = ts

    def yield_data(self):
        # Yield low then high
        if self.lo:
            yield self.data & (2 ** 32 - 1)
        if self.hi:
            yield self.data >> 32
        self.data = -1


class TsEndCaptureEntry(CaptureEntry):
    data = -1
    lo = False
    hi = False

    def on_falling_gate(self, ts):
        self.data = ts

    def yield_data(self):
        # Yield low then high
        if self.lo:
            yield self.data & (2 ** 32 - 1)
        if self.hi:
            yield self.data >> 32
        self.data = -1


class TsCaptureCaptureEntry(CaptureEntry):
    lo = False
    hi = False

    def on_capture(self, ts, gate):
        # Yield low then high
        if self.lo:
            yield ts & (2 ** 32 - 1)
        if self.hi:
            yield ts >> 32


class SampleCaptureEntry(CaptureEntry):
    data = 0
    ts = 0

    def __init__(self, idx, shift):
        super(SampleCaptureEntry, self).__init__(idx)
        self.shift = shift

    def on_rising_gate(self, ts):
        self.ts = ts

    def on_falling_gate(self, ts):
        self.data += ts - self.ts

    def yield_data(self):
        yield self.data >> self.shift
        self.data = 0


class BitsCaptureEntry(CaptureEntry):
    def __init__(self, idx, quadrant):
        super(BitsCaptureEntry, self).__init__(idx)
        self.quadrant = quadrant

    def on_capture(self, ts, gate):
        bits = BlockSimulation.bit_bus[self.quadrant * 32:(self.quadrant + 1) * 32]
        yield BlockSimulation.bits_to_int(bits)


class PcapSimulation(BlockSimulation):
    ENABLE, GATE, TRIG, TRIG_EDGE, SHIFT_SUM, HEALTH, ACTIVE, TS_START, TS_END, TS_TRIG, SAMPLES, BITS0, BITS1, BITS2, BITS3 = PROPERTIES
    tick_data = True

    def __init__(self):
        # This is the pending data to push
        self.buf = np.zeros(MAX_BUFFER, dtype=np.int32)
        self.buf_len = 0
        self.buf_produced = 0
        self.pend_data = None
        self.pend_error = None
        # The ts at enable
        self.ts_enable = 0
        # These are the capture entries in the order they should be produced
        self.capture_entries = []
        self.capture_lookup = {}  # {pos_bus index: [CaptureEntry]}
        # This lets us find the name of the field from the index
        self.ext_names = {}
        # These fields are from REG* rather than the block_config
        self.START_WRITE = 0
        self.WRITE = 0
        self.ARM = 0
        self.DISARM = 0
        self.DATA = 0
        # self.add_properties()
        i = 0
        for NAME in PROPERTIES:

            if NAME.fget.im_self.type == "ext_out timestamp":
                # something like 37 38
                self.ext_names[i + 32] = NAME.fget.im_self.name + "_L"
                i += 1
                self.ext_names[i + 32] = NAME.fget.im_self.name + "_H"
                i += 1
            elif "ext_out" in NAME.fget.im_self.type:
                # one of the others
                self.ext_names[i + 32] = NAME.fget.im_self.name
                i += 1

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(PcapSimulation, self).on_changes(ts, changes)

        ret = None
        # This is a ConfigBlock object for use to get our strings from
        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)

        # ext_bus indexes are written here
        if "START_WRITE" in changes:
            self.capture_entries = []
            self.capture_lookup = {}
        elif "WRITE" in changes:
            self.add_capture_entry(changes["WRITE"])

        # Arm control from *REG.PCAP_[DIS]ARM
        if "DISARM" in changes:
            self.do_disarm()
        elif "ARM" in changes:
            self.do_arm(ts)

        # Handle input signals
        if self.ACTIVE:
            if NAMES.ENABLE in changes:
                if changes[NAMES.ENABLE]:
                    self.do_enable(ts)
                else:
                    self.do_disarm()
            if self.ENABLE:
                if NAMES.GATE in changes:
                    self.do_gate(ts, self.GATE)
                if self.GATE:
                    self.do_gated_value(ts, changes.get("POS_BUS", []))
                if NAMES.TS_TRIG in changes:
                    if self.CAPTURE_EDGE == 0 and changes[NAMES.CAPTURE] or \
                            self.CAPTURE_EDGE == 1 and not changes[NAMES.CAPTURE] \
                            or self.CAPTURE_EDGE == 2:
                        self.do_capture(ts)

        # If there was an error then produce it
        if ts == self.pend_error:
            # The only error we can have is if captures are too close together
            self.pend_error = None
            self.ACTIVE = 0
            self.HEALTH = TOO_CLOSE
        elif self.pend_error is not None:
            ret = self.pend_error

        # If there was pending_data then write it here
        if self.tick_data and self.pend_data:
            if self.buf_len > self.buf_produced:
                self.pend_data.append(self.buf[self.buf_produced])
                self.buf_produced += 1
            else:
                self.pend_data.append(None)
            data = self.pend_data.popleft()
            print "It GOES HERE AT SOME POINT"
            print self.pend_data
            if data is not None:
                self.DATA = data
            ret = ts + 1
        return ret

    def add_capture_entry(self, data):
        # Bottom 4 bits are the mode
        mode = data & 0xf
        # Top 6 bits are the index
        i = data >> 4
        # The list we will store it in
        entries = self.capture_lookup.setdefault(i, [])
        if i < 32:
            # This is an entry on the pos_bus
            if mode == VALUE:
                entry = ValueCaptureEntry(i)
            elif mode == DIFFERENCE:
                entry = DifferenceCaptureEntry(i)
            elif mode == SUM_L:
                entry = SumCaptureEntry.definitely_create(
                    entries, i, self.SHIFT_SUM)
                entry.lo = True
            elif mode == SUM_H:
                entry = SumCaptureEntry.create_if_not_existing(
                    entries, i, self.SHIFT_SUM)
                entry.hi = True
            elif mode == MIN:
                entry = MinCaptureEntry(i)
            elif mode == MAX:
                entry = MaxCaptureEntry(i)
            else:
                raise ValueError("Bad mode %d" % mode)
        else:
            # This is a special entry
            name = self.ext_names[i]
            if name.startswith("TS_"):
                if name.startswith("TS_START"):
                    cls = TsStartCaptureEntry
                elif name.startswith("TS_END"):
                    cls = TsEndCaptureEntry
                elif name.startswith("TS_TRIG"):
                    cls = TsCaptureCaptureEntry
                else:
                    raise ValueError("Bad name %s" % name)
                if name.endswith("_L"):
                    entry = cls.definitely_create(entries, i)
                    entry.lo = True
                else:
                    entry = cls.create_if_not_existing(entries, i)
                    entry.hi = True
            elif name.startswith("BITS"):
                entry = BitsCaptureEntry(i, int(name[-1]))
            elif name == "SAMPLES":
                entry = SampleCaptureEntry(i, self.SHIFT_SUM)
            else:
                raise ValueError("Bad name %s" % name)
        if entry not in entries:
            entries.append(entry)
            self.capture_entries.append(entry)

    def do_arm(self, ts):
        # Mark as active and reset error
        self.ACTIVE = 1
        self.HEALTH = OK
        self.buf_len = 0
        self.buf_produced = 0
        self.pend_data = deque((None, None))
        # If we are already enabled then start now
        if self.ENABLE:
            self.do_enable(ts)

    def do_disarm(self):
        if self.ACTIVE:
            self.ACTIVE = 0

    def do_enable(self, ts):
        self.ts_enable = ts
        if self.GATE:
            for entry in self.capture_entries:
                entry.on_rising_gate(0)

    def do_gate(self, ts, gate):
        # Make ts relative to ts at enable
        ts -= self.ts_enable
        for entry in self.capture_entries:
            if gate:
                entry.on_rising_gate(ts)
            else:
                entry.on_falling_gate(ts)

    def do_gated_value(self, ts, indexes):
        # Make ts relative to ts at enable
        ts -= self.ts_enable
        for index in indexes:
            for entry in self.capture_lookup.get(index, []):
                entry.on_gated_value(ts)

    def do_capture(self, ts):
        new_data = []
        for entry in self.capture_entries:
            # Make ts relative to ts at enable
            for nd in entry.on_capture(ts - self.ts_enable, self.GATE):
                new_data.append(nd)
        self.push_data(ts, new_data)

    def push_data(self, ts, new_data):
        """Push the data from our ext_bus into the output buffer. Note that
        in the FPGA this is clocked out one by one, but we push it all in one
        go and make sure we don't get another push until we've done all but one
        sample"""
        if self.tick_data and self.buf_len > self.buf_produced:
            # Told to push more data when we hadn't finished the last capture
            self.pend_error = ts + 2
        else:
            new_size = len(new_data)
            self.buf[self.buf_len:self.buf_len + new_size] = new_data
            self.buf_len += len(new_data)

    def read_data(self, max_length):
        if self.buf_len > 0:
            data_length = min(self.buf_len, max_length)
            result = +self.buf[:data_length]
            self.buf[:self.buf_len - data_length] = \
                self.buf[data_length:self.buf_len]
            self.buf_len -= data_length
            return result
        elif self.ACTIVE:
            # Return empty array if there's no data but we're still active
            return self.buf[:0]
        else:
            # Return None to indicate end of data capture stream
            return None
