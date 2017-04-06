from common.python.pandablocks.block import Block


class Filter(Block):
    def __init__(self):
        self.scale = {0:0, 1:1, 2:2}

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

