
from collections import deque
from common.python.pandablocks.block import Block


class Filter(Block):
    def __init__(self):
        self.latch = 0
        self.nsamples = 0
        self.sum = 0
        self.queue = deque()
        self.ts_sum_start = 0
        self.ts_sum = 0
        self.inp_prev = 0

    def set_values(self, ts):
        self.OUT = 0
        if self.MODE == 0:
            self.set_difference()
        elif self.MODE == 1:
            self.set_avearage(ts)

    def set_difference(self):
        self.latch = self.INP

    def set_avearage(self, ts):
        self.nsamples = 0
        self.sum = 0
        self.ts_sum_start = ts
        self.ts_sum = ts
        self.inp_prev = self.INP

    def handle_trig(self, ts):
        if self.MODE == 0:
            self.difference(ts)
        elif self.MODE == 1:
            self.average(ts)

    def difference(self, ts):
        self.OUT = self.INP-self.latch
        self.latch = self.INP
        self.READY = 1
        self.queue.append((ts + 1, 0))

    def average(self, ts):
        self.nsamples = ts - self.ts_sum_start
        self.sum += self.INP * (ts - self.ts_sum)
        self.OUT = self.sum / (self.nsamples)
        self.READY = 1
        self.queue.append((ts + 1, 0))

    def do_sum(self, ts):
        self.sum += self.inp_prev * (ts - self.ts_sum - 1) + self.INP
        self.ts_sum = ts
        self.inp_prev = self.INP
        if sum > (2**32 - 1):
            self.ERR = 1
            self.ENABLE == 0

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Set values on rising edge of ENABLE
        if changes.get(b.ENABLE) == 1:
            self.set_values(ts)

        if b.INP in changes:
            self.do_sum(ts)

        # Do actions on rising edge of TRIG
        if changes.get(b.TRIG) == 1:
            if self.ENABLE == 1:
                self.handle_trig(ts)
                self.set_avearage(ts)

        # End the 1 cycle pulse on ready
        if self.queue and self.queue[0][0] == ts:
            self.queue.popleft()
            self.READY = 0

