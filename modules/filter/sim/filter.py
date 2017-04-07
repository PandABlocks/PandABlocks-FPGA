
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

    def difference(self):
        pass

    def average(self):
        pass

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
            self.OUT = 0
            if self.MODE == 0:
                self.latch = self.INP
            elif self.MODE == 1:
                self.nsamples = 0
                self.sum = 0
                self.ts_sum_start = ts
                self.ts_sum = ts
                pass

        # Do actions on rising edge of TRIG
        if changes.get(b.TRIG) == 1:
            if self.ENABLE == 1:
                if self.MODE == 0:
                    self.OUT = self.INP-self.latch
                    self.latch = self.INP
                    self.READY = 1
                    self.queue.append((ts + 1, 0))
                elif self.MODE == 1:
                    self.nsamaples = ts - self.ts_sum_start
                    self.sum += self.INP * (ts - self.ts_sum)
                    self.OUT = self.sum / (self.nsamaples + 1)
                    pass

        if b.INP in changes:
            self.sum += self.INP
            self.ts_sum = ts

            if sum > (2**32 - 1):
                self.ERR = 1
                #stop processing

        # End the 1 cycle pulse on ready
        if self.queue and self.queue[0][0] == ts:
            self.READY = 0

