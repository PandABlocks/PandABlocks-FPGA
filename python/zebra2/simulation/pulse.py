from collections import deque

from .block import Block


# max queue size
MAX_QUEUE = 1023

# min FPGA deadtime between queued pulses
MIN_QUEUE_DELTA = 4

# time taken to clear queue
QUEUE_CLEAR_TIME = 4


class Pulse(Block):

    def __init__(self):
        self.queue = deque()
        self.valid_ts = 0

    def do_pulse(self, ts, changes):
        """We've received a bit event on INP, so queue some output values
        based on DELAY and WIDTH"""
        # If the queue isn't valid at the moment then error
        # If there isn't room for 2 on the queue then error
        width = self.WIDTH_L + (self.WIDTH_H << 32)
        delay = self.DELAY_L + (self.DELAY_H << 32)
        if ts < self.valid_ts or len(self.queue) + 2 > MAX_QUEUE:
            self.PERR = 1
            self.MISSED_CNT += 1
            self.ERR_OVERFLOW = 1
        # If there is no specified width then use the width of input pulse
        elif width == 0:
            self.queue.append((ts + delay, self.INP))
        elif self.INP:
            # generate both high and low queue from inp
            start = ts + delay
            # make sure that start is after any pulse on queue
            if self.queue and start < self.queue[-1][0] + MIN_QUEUE_DELTA:
                self.PERR = 1
                self.MISSED_CNT += 1
                self.ERR_PERIOD = 1
            else:
                self.queue.append((start, 1))
                self.queue.append((start + width, 0))

    def do_reset(self, ts):
        """Reset the block, either called on rising edge of RST input or
        when FORCE_RST reg is written to"""
        self.MISSED_CNT = 0
        self.ERR_OVERFLOW = 0
        self.ERR_PERIOD = 0
        self.PERR = 0
        self.OUT = 0
        self.do_clear_queue(ts)

    def do_clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.valid_ts = ts + QUEUE_CLEAR_TIME
        self.queue.clear()

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block
        # This is the next time we need to be called
        next_ts = None

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)
            if name in (b.DELAY_L, b.DELAY_H, b.WIDTH_L, b.WIDTH_H):
                self.do_clear_queue(ts)

        # Check reset and pulse inputs
        if b.FORCE_RST in changes or changes.get(b.RST, None):
            self.do_reset(ts)
        elif b.INP in changes:
            self.do_pulse(ts, changes)

        # if we have an pulse on our queue that is due, produce it
        if self.queue and self.queue[0][0] == ts:
            # generate output value
            self.OUT = self.queue.popleft()[1]

        # if we have anything else on the queue, return when it's due
        if self.queue:
            next_ts = self.queue[0][0]
            assert next_ts >= ts, "Going back in time %s >= %s" % (next_ts, ts)

        # Event list changed, update status word
        self.QUEUE = len(self.queue)
        return next_ts
