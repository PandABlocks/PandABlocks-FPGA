from .block import Block
from .event import Event


class Counter(Block):

    def __init__(self, num):
        super(Counter, self).__init__(num)
        self.dir = 0
        self.step = 0
        self.count = 0
        self.enable = 0

    def do_trigger(self, next_event, event):
        if self.dir == 0:
            self.count += self.step
        elif self.dir == 1:
            self.count -= self.step
        next_event.pos[self.COUNT] = self.count

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "START" and value:
                    self.count = value
                elif name == "STEP" and value:
                    self.step = value
                elif name == "SOFT_ENABLE" and value:
                    self.enable = 1
        # if we got a reset, and it was high, do a reset
        if event.bit.get(self.ENABLE, None) == 1:
            self.enable = 1
        elif event.bit.get(self.ENABLE, None) == 0:
            self.enable = 0
        # if we got a set, then process it
        # print "--TS--", event.ts
        # print "EE", event.bit.get(self.DIR, None)
        if event.bit.get(self.DIR, None) == 1:
            self.dir = 1
        elif event.bit.get(self.DIR, None) == 0:
            self.dir = 0
        if event.bit.get(self.TRIGGER, None) == 1:
            if self.enable:
                self.do_trigger(next_event, event)
        # return any changes and next ts
        return next_event
