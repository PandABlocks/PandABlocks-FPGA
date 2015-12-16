from .block import Block
from .event import Event


class Lut(Block):

    def __init__(self, num):
        super(Lut, self).__init__(num)
        self.inputs = {'A':0, 'B':0, 'C':0, 'D':0, 'E':0}

    def do_lookup(self, next_event, event):
        """We've received a bit event on an INPUT channel, set the local,
        copies of the inputs and set the output from address value the inputs make."""
        input_map = {self.INPA:'A', self.INPB:'B', self.INPC:'C', self.INPD:'D', self.INPE:'E'}
        for name, val in event.bit.items():
            self.inputs[input_map[name]] = val
        x = self.get_address(self.inputs)
        next_event.bit[self.VAL] = int('{0:032b}'.format(self.FUNC)[x])

    def get_address(self, input):
        return (input['A'] << 4) + (input['B'] << 3) + (input['C'] << 2) + (input['D'] << 1) + input['E']

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
        # if we got an input, then process it
        if any(x in event.bit for x in [self.INPA, self.INPB, self.INPC, self.INPD, self.INPE]):
            self.do_lookup(next_event, event)
        # return any changes and next ts
        return next_event
