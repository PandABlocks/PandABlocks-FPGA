import numpy as np

from common.python.pandablocks.block import Block

UP = 0
DOWN = 1


class Counter(Block):

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for us to get our strings from
        b = self.config_block
        if self.MAX == 0 and self.MIN == 0:
            MIN = np.iinfo(np.int32).min
            MAX = np.iinfo(np.int32).max
        else:
            MIN = self.MIN
            MAX = self.MAX
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        if changes.get(b.ENABLE, None):
            self.OUT = self.START

        # process trigger on rising edge
        if self.ENABLE and b.TRIG in changes:
            if changes[b.TRIG]:
                if self.STEP == 0:
                    step = 1
                else:
                    step = self.STEP
                if self.DIR == DOWN:
                    step = -step
                self.OUT += step
                if self.OUT > MAX:
                    self.OUT -= MAX - MIN + 1
                    self.CARRY = 1
                elif self.OUT < MIN:
                    self.OUT += MAX - MIN + 1
                    self.CARRY = 1
            elif self.CARRY:
                self.CARRY = 0
