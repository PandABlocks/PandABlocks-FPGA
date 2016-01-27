from .block import Block


class Counter(Block):

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for us to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)
            if name == b.START:
                self.COUNT = value

        # process trigger on rising edge
        if self.ENABLE and b.TRIGGER in changes:
            if changes[b.TRIGGER]:
                if self.DIR == 0:
                    self.COUNT += self.STEP
                else:
                    self.COUNT -= self.STEP
                if self.COUNT > (2**32 - 1):
                    self.CARRY = 1
            elif self.CARRY:
                self.CARRY = 0
