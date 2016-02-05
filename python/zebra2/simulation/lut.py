from .block import Block


class Lut(Block):
    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # The row of our truth table is is calculated by treating 0bABCDE as a
        # binary number with A as MSB and E as LSB
        row = (self.INPA << 4) + (self.INPB << 3) + (self.INPC << 2) + \
            (self.INPD << 1) + self.INPE
        # We then shift the 32-bit FUNC to get the right row in the LSB, and
        # extract this as self.VAL
        self.VAL = (self.FUNC >> row) & 1
