from common.python.pandablocks.block import Block


RISING = 0
FALLING = 1
EITHER = 2


class Srgate(Block):

    def inp_matches_edge(self, inp, edge):
        if edge == RISING and inp == 1 or edge == FALLING and inp == 0 \
                or edge == EITHER and inp is not None:
            return True

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Force regs take priority
        if b.FORCE_RST in changes:
            self.OUT = 0
        elif b.FORCE_SET in changes:
            self.OUT = 1
        elif self.inp_matches_edge(changes.get(b.RST, None), self.RST_EDGE):
            self.OUT = 0
        elif self.inp_matches_edge(changes.get(b.SET, None), self.SET_EDGE):
            self.OUT = 1
