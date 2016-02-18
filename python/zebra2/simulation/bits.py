from .block import Block


class Bits(Block):

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # if we got register changes, handle those
        for name, value in changes.items():
            setattr(self, name, value)
            if name in ['A', 'B', 'C', 'D']:
                setattr(self, 'OUT'+name, value)
