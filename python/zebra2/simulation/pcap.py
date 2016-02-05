import numpy as np

from .block import Block


# This is the max size of internal buffer of captured data before being shipped
# off
MAX_BUFFER = 1 << 16


class Pcap(Block):
    tick_data = True

    def __init__(self):
        # This is the ext_bus values to copy
        self.ext_bus = np.zeros(64, dtype=np.int32)
        # These are the ext_bus indexes to capture and the generated masks
        self.store_indices = []
        self.capture_mask = np.zeros(32, dtype=np.bool_)
        self.frame_mask = np.zeros(32, dtype=np.bool_)
        self.alt_frame_mask = np.zeros(32, dtype=np.bool_)
        self.ext_mask = np.zeros(64, dtype=np.bool_)
        self.pos_bus_cache = np.zeros(32, dtype=np.int32)
        # This is the pending data to push
        self.buf = np.zeros(MAX_BUFFER, dtype=np.int32)
        self.buf_len = 0
        self.buf_produced = 0
        # This is the last frame ts
        self.ts_frame = 0
        # This is when we raised ACTIVE
        self.ts_start = 0
        # This forward lookup of name to ext_bus
        self.ext_names = {}
        # Has there been a capture during this frame?
        self.live_frame = False
        for name, field in self.config_block.fields.items():
            if field.cls == "ext_out":
                if len(field.reg) > 1:
                    self.ext_names[name] = [int(arg) for arg in field.reg]
                else:
                    self.ext_names[name] = int(field.reg[0])
        # Add some entries for encoder extended
        enc = self.parser.blocks["INENC"]
        for i, v in enumerate(enc.fields["POSN"].reg[5:]):
            self.ext_names["ENC%d" % (i + 1)] = int(v)
        # And for the ADC accumulator
        adc = self.parser.blocks["ADC"]
        for i, v in enumerate(adc.fields["DATA"].reg[9:]):
            self.ext_names["DATA%d" % (i + 1)] = int(v)

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)

        # ext_bus indexes are written here
        if b.START_WRITE in changes:
            self.store_indices = []
        elif b.WRITE in changes:
            self.store_indices.append(changes[b.WRITE])

        # Arm control from *REG.PCAP_[DIS]ARM
        if b.DISARM in changes:
            self.ACTIVE = 0
        elif b.ARM in changes:
            # Mark as active and reset error
            self.ACTIVE = 1
            self.ERROR = 0
            self.ERR_STATUS = 0
            self.calculate_masks()
            self.ts_frame = -1
            self.ts_start = ts
            self.live_frame = False
            self.buf_len = 0
            self.buf_produced = 0

        # Disarm from ENABLE falling edge
        if changes.get(b.ENABLE, None) == 0:
            self.ACTIVE = 0

        # Handle input signals
        if self.ACTIVE and self.ENABLE:
            # if framing signal then process FRAMING_MASK selected signals
            if self.FRAMING_ENABLE and self.FRAMING_MASK and \
                    changes.get(b.FRAME, None):
                self.do_frame(ts)
            # if capture signal then process captured signals
            if changes.get(b.CAPTURE):
                self.do_capture(ts)

        # If there was pending_data then write it here
        if self.tick_data and self.buf_len > self.buf_produced:
            self.DATA = self.buf[self.buf_produced]
            self.buf_produced += 1
            if self.buf_len > self.buf_produced:
                return ts + 1

    def calculate_masks(self):
        """Calculate the masks of for framed and captured data, and alternate
        framing. The ext_mask tells us what we extract from the calculated
        ext_bus"""
        self.frame_mask.fill(0)
        self.capture_mask.fill(0)
        self.alt_frame_mask.fill(0)
        for i in self.store_indices:
            # is it pos_bus?
            if i < 32:
                # is it framed?
                if (self.FRAMING_MASK >> i) & 1:
                    # is it special?
                    if (self.FRAMING_MODE >> i) & 1:
                        self.alt_frame_mask[i] = 1
                    else:
                        self.frame_mask[i] = 1
                else:
                    self.capture_mask[i] = 1
            self.ext_mask[i] = 1
        self.store_indices = np.array(self.store_indices)

    def do_frame(self, ts):
        """Handle a frame signal"""
        if self.ts_frame > -1 and self.live_frame:
            b = self.config_block
            # Frame pos bus
            diff = self.pos_bus - self.pos_bus_cache
            self.ext_bus[self.frame_mask] = diff[self.frame_mask]
            # Alt mode is average
            avg = (self.pos_bus + self.pos_bus_cache) / 2
            self.ext_bus[self.alt_frame_mask] = avg[self.alt_frame_mask]
            # Ext bus
            len_idx = self.ext_names[b.FRAME_LENGTH]
            if self.ext_mask[len_idx]:
                self.ext_bus[len_idx] = ts - self.ts_frame
            # TODO: ADC Count, ext
            self.push_data(ts)
            self.live_frame = False
        # Cache the pos bus and last ts_frame
        self.pos_bus_cache[:] = self.pos_bus
        self.ts_frame = ts

    def do_capture(self, ts):
        """Handle a capture signal. This will have different behaviour in framed
        and non-framed mode"""
        b = self.config_block
        if self.FRAMING_ENABLE:
            if self.live_frame:
                # more than one CAPTURE within a frame, error
                self.ERR_STATUS = 1
                self.ERROR = 1
                self.ACTIVE = 0
                return
            elif self.ts_frame == -1:
                # capture signal before first frame signal
                self.ERR_STATUS = 3
                self.ERROR = 1
                self.ACTIVE = 0
                return
            self.live_frame = True
        # Capture pos bus
        self.ext_bus[self.capture_mask] = self.pos_bus[self.capture_mask]
        # Ext bus
        ts_idx = self.ext_names[b.CAPTURE_TS]
        if self.ext_mask[ts_idx[0]]:
            self.ext_bus[ts_idx[0]] = (ts - self.ts_start) & (2 ** 32 - 1)
            self.ext_bus[ts_idx[1]] = (ts - self.ts_start) >> 32
        off_idx = self.ext_names[b.CAPTURE_OFFSET]
        if self.ext_mask[off_idx]:
            self.ext_bus[off_idx] = ts - self.ts_frame
        # bit arrays
        for i, suff in enumerate("ABCD"):
            bit_idx = self.ext_names["BIT%s" % suff]
            if self.ext_mask[bit_idx]:
                bits = self.bit_bus[i*32:(i+1)*32]
                self.ext_bus[bit_idx] = Block.bits_to_int(bits)
        # encoder extensions
        for i in range(4):
            enc_idx = self.ext_names["ENC%d" % (i + 1)]
            if self.ext_mask[enc_idx]:
                self.ext_bus[enc_idx] = self.enc_bus[i]
        # if no framing, push out values now
        if not self.FRAMING_ENABLE:
            self.push_data(ts)
        else:
            # just mark as live frame
            self.live_frame = True

    def push_data(self, ts):
        """Push the data from our ext_bus into the output buffer. Note that
        in the FPGA this is clocked out one by one, but we push it all in one
        go and make sure we don't get another push until self.pushing_til"""
        if self.tick_data and self.buf_len > self.buf_produced:
            # Told to push more data when we hadn't finished the last capture
            self.ERR_STATUS = 2
            self.ERROR = 1
            self.ACTIVE = 0
        else:
            new_data = self.ext_bus[self.store_indices]
            new_size = len(new_data)
            self.buf[self.buf_len:self.buf_len+new_size] = new_data
            self.buf_len += len(new_data)
