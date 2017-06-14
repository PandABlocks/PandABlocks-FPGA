from common.python.pandablocks.block import Block


class Srgate(Block):

    def __init__(self):
        self.RST_EDGE = 1
        self.SET_EDGE = 1

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
        elif changes.get(b.RST, None) == self.RST_EDGE and self.FORCE_SET != 1:
            self.OUT = 0
        elif changes.get(b.SET, None) == self.SET_EDGE and self.FORCE_RST != 1:
            self.OUT = 1
        elif b.SET in changes and self.SET_EDGE == 2 and self.FORCE_RST != 1:
            self.OUT = 1
        elif b.RST in changes and self.RST_EDGE == 2 and self.FORCE_SET != 1:
            self.OUT = 0