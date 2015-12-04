from enum import Enum
from collections import deque

from .block import Block
from .event import Event

# first pulse options
OUTN = 0
OUTD = 1


class Div(Block):

    def __init__(self, num):
        super(Div, self).__init__(num)

    def do_pulse(self, next_event, event):
        """We've received a bit event on INP, on a rising edge send it out of
        OUTN or OUTD, on a falling edge set them both low"""
        inp = event.bit[self.INP]
        if inp:
            self.COUNT += 1
            if self.COUNT >= self.DIVISOR:
                self.COUNT = 0
                next_event.bit[self.OUTD] = 1
            else:
                next_event.bit[self.OUTN] = 1
        else:
            next_event.bit[self.OUTD] = 0
            next_event.bit[self.OUTN] = 0

    def do_reset(self, next_event, event):
        """Reset the block, either called on rising edge of RESET input or
        when FORCE_RESET reg is written to"""
        next_event.bit[self.OUTD] = 0
        next_event.bit[self.OUTN] = 0
        if self.FIRST_PULSE == OUTN:
            self.COUNT = 0
        else:
            self.COUNT = self.DIVISOR - 1

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
            self.do_reset(next_event, event)
        # if we got a reset, and it was high, do a reset
        if event.bit.get(self.RESET, None):
            self.do_reset(next_event, event)
        # if we got an input, then process it
        elif self.INP in event.bit:
            self.do_pulse(next_event, event)
        # return any changes and next ts
        return next_event
