from .block import Block
from .event import Event
from collections import deque

class Pcomp(Block):

    def __init__(self, num):
        super(Pcomp, self).__init__(num)
        self.enable = 0
        self.queue = deque()
        self.pulse_count = 0

    def do_generate_pulse(self, next_event, event):
        next_event.bit[self.PULSE] = 1
        self.queue.append((event.ts + self.WIDTH, self.WIDTH))
        self.queue.append((event.ts + self.STEP, self.STEP))

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "NUM" and value:
                    self.pulse_count = value - 1
                elif name == "RELATIVE" and value:
                    #set relative
                    pass
                elif name == "LUT_ENABLE" and value:
                    #start lut enable mode
                    pass
                elif name == "LUT_SAMPLES" and value:
                    #set LUT samples
                    pass
                elif name == "LUT_ADDR" and value:
                    #set LUT address
                    pass
        if event.bit.get(self.ENABLE, None) == 1:
            # self.do_pos_compare_start(next_event, event)
            self.enable = 1
            next_event.bit[self.ACT] = 1
        elif event.bit.get(self.ENABLE, None) == 0:
            self.enable = 0
            next_event.bit[self.ACT] = 0
            next_event.bit[self.PULSE] = 0
            self.queue.clear()
        if event.pos.get(self.POSN, None) == self.START and self.enable:
            self.do_generate_pulse(next_event, event)
        # if we have a pulse on our queue that is due, produce it
        if self.queue and self.queue[0][0] == event.ts:
            # generate output value
            if self.queue[0][1] == self.START:
                next_event.bit[self.PULSE] = 1
                self.do_generate_pulse(next_event, event)
            elif self.queue[0][1] == self.WIDTH:
                next_event.bit[self.PULSE] = 0
            elif self.queue[0][1] == self.STEP:
                if self.pulse_count > 0:
                    self.do_generate_pulse(next_event, event)
                    next_event.bit[self.PULSE] = 1
                    self.pulse_count -= 1
                elif self.pulse_count == 0:
                    next_event.bit[self.ACT] = 0
            self.queue.popleft()
        # return any changes and next ts
        return next_event
