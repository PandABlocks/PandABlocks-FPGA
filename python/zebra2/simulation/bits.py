from .block import Block
from .event import Event


class Bits(Block):

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        for name, value in event.reg.items():
            setattr(self, name, value)
            if name.endswith("_SET"):
                bus_index = getattr(self, name[:-len("_SET")])
                next_event.bit[bus_index] = value
        # return any changes and next ts
        return next_event
