from enum import Enum
from collections import deque

from .block import Block
from .event import Event

# max queue size
MAX_QUEUE = 1023

# min FPGA deadtime between queue
DEADTIME = 2


class Pulse(Block):

    def __init__(self, num):
        super(Pulse, self).__init__(num)
        self.queue = deque()
        self.valid_ts = 0

    def do_pulse(self, next_event, event):
        inp = event.bit[self.INP]
        # If the queue isn't valid at the moment then error
        # If there isn't room for 2 on the queue then error
        if event.ts < self.valid_ts or len(self.queue) + 2 > MAX_QUEUE:
            next_event.bit[self.PERR] = 1
            self.MISSED_CNT += 1
            self.ERR_OVERFLOW = 1
        # If there is no specified width then use the width of input pulse
        elif self.WIDTH == 0:
            self.queue.append((event.ts + self.DELAY, inp))
        elif inp:
            # generate both high and low queue from inp
            start = event.ts + self.DELAY
            # make sure that start is after any queue on queue
            if self.queue and start < self.queue[-1][0] + DEADTIME:
                next_event.bit[self.PERR] = 1
                self.MISSED_CNT += 1
                self.ERR_PERIOD = 1
            else:
                self.queue.append((start, 1))
                self.queue.append((start + self.WIDTH, 0))

    def do_reset(self, next_event, event):
        self.MISSED_CNT = 0
        self.ERR_OVERFLOW = 0
        self.ERR_PERIOD = 0
        next_event.bit[self.PERR] = 0
        next_event.bit[self.OUT] = 0
        self.valid_ts = event.ts + 4        

    def on_event(self, event):
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "FORCE_RESET":
                    self.do_reset(next_event, event)
            self.queue.clear()
            self.QUEUE = 0
        # if we got a reset, and it was high, do a reset
        if event.bit.get(self.RESET, None):
            self.do_reset(next_event, event)
        # if we got an input, then process it
        elif self.INP in event.bit:
            self.do_pulse(next_event, event)
        # if we have an pulse on our queue that is due, produce it
        if self.queue and self.queue[0][0] == event.ts:
            # generate output value
            next_event.bit[self.OUT] = self.queue.popleft()[1]
        # if we have anything else on the queue, return when it's due
        if self.queue:
            next_event.ts = self.queue[0][0]
            assert next_event.ts >= event.ts, \
                "Going back in time %s >= %s" % (next_event.ts, event.ts)                
        # Event list changed, update status word
        self.QUEUE = len(self.queue)
        # return any changes and next ts
        return next_event