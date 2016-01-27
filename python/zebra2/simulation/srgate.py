from .block import Block


class Srgate(Block):

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
            self.VAL = 0
        elif b.FORCE_SET in changes:
            self.VAL = 1
        elif changes.get(b.RST, None) == self.RST_EDGE:
            self.VAL = 0
        elif changes.get(b.SET, None) == self.SET_EDGE:
            self.VAL = 1
