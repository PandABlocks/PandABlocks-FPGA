from .block import Block
from .event import Event

class Lut(Block):

    def do_pulse(self, next_event, event):
        pass


    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
        # if we got an input, then process it
        if any(x in event.bit for x in [self.INPA, self.INPB, self.INPC, self.INPD, self.INPE ]):
            self.do_pulse(next_event, event)
        # return any changes and next ts
        return next_event