from common.python.pandablocks.block import Block


class Div(Block):

    def __init__(self):
        self.counter = 0
        self.first_pulse_d = 1
        self.first_pulse_n = 0


    def do_pulse(self, inp):
        """We've received a bit event on INP, on a rising edge send it out of
        OUTN or OUTD, on a falling edge set them both low"""
        if self.ENABLE:
            if inp:
                self.counter += 1
                if self.counter >= self.DIVISOR:
                    self.counter = 0
                    self.OUTD = 1
                else:
                    self.OUTN = 1
            else:
                self.OUTD = 0
                self.OUTN = 0
        self.COUNT = self.counter

    def do_reset(self):
        """Reset the block, either called on rising edge of RST"""
        self.OUTD = 0
        self.OUTN = 0
        if self.FIRST_PULSE == self.first_pulse_n:
            self.counter = 0
        else:
            self.counter = self.DIVISOR - 1

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)
            if name not in (b.INP, b.ENABLE):
                self.do_reset()

        #Reset on the falling edge of ENABLE or other register write
        if changes.get(b.ENABLE, None) == 0:
            self.do_reset()
            self.COUNT = self.counter

        elif b.INP in changes:
            self.do_pulse(changes[b.INP])
