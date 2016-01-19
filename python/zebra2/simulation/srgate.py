from .block import Block
from .event import Event

class Srgate(Block):

    def do_set(self, next_event, event):
        """Set the output value high on the acting edge of a SET input or on a
        FORCE SET action"""
        next_event.bit[self.VAL] = 1

    def do_reset(self, next_event, event):
        """Reset the block, either called on the acting edge of RESET input or
        on a FORCE RESET action"""
        next_event.bit[self.VAL] = 0

    def do_process_inputs(self, next_event, event):
        # if we got a reset, and it was high, do a reset
        if event.bit.get(self.RESET, None) == self.RESET_EDGE:
            self.do_reset(next_event, event)
        # if we got a set, then process it
        elif event.bit.get(self.SET, None) == self.SET_EDGE:
            self.do_set(next_event, event)

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "FORCE_RESET" and value:
                    self.do_reset(next_event, event)
                elif name == "FORCE_SET" and value:
                    self.do_set(next_event, event)
                else:
                    self.do_process_inputs(next_event, event)
        else:
            self.do_process_inputs(next_event, event)
        # return any changes and next ts
        return next_event
