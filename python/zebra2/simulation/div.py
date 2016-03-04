from .block import Block


# first pulse options
OUTN = 0
OUTD = 1


class Div(Block):

    def do_pulse(self, inp):
        """We've received a bit event on INP, on a rising edge send it out of
        OUTN or OUTD, on a falling edge set them both low"""
        if self.ENABLE:
            if inp:
                self.COUNT += 1
                if self.COUNT >= self.DIVISOR:
                    self.COUNT = 0
                    self.OUTD = 1
                else:
                    self.OUTN = 1
            else:
                self.OUTD = 0
                self.OUTN = 0

    def do_reset(self):
        """Reset the block, either called on rising edge of RST"""
        self.OUTD = 0
        self.OUTN = 0
        if self.FIRST_PULSE == OUTN:
            self.COUNT = 0
        else:
            self.COUNT = self.DIVISOR - 1

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes, and flag clear queue
        reset = False
        for name, value in changes.items():
            setattr(self, name, value)
            if name not in (b.INP, b.ENABLE):
                reset = True

        #Reset on the falling edge of ENABLE or other register write
        if reset or changes.get(b.ENABLE, None) == 0:
            self.do_reset()
        elif b.INP in changes:
            self.do_pulse(changes[b.INP])
