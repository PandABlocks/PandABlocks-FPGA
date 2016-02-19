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
                self.OUT = value

        if changes.get(b.ENABLE, None):
            self.OUT = self.START

        # process trigger on rising edge
        if self.ENABLE and b.TRIG in changes:
            if changes[b.TRIG]:
                if self.DIR == 0:
                    self.OUT += self.STEP
                else:
                    self.OUT -= self.STEP
                if self.OUT > (2**32 - 1):
                    self.CARRY = 1
            elif self.CARRY:
                self.CARRY = 0
