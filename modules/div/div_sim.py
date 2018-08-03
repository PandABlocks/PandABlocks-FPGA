from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict, Optional


NAMES, PROPERTIES = properties_from_ini(__file__, "div.block.ini")


class DivSimulation(BlockSimulation):

    DIVISOR, FIRST_PULSE, INP, ENABLE, OUTD, OUTN, COUNT = PROPERTIES

    def __init__(self):
        self.first_pulse_d = 1
        self.first_pulse_n = 0

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
        if self.FIRST_PULSE == self.first_pulse_n:
            self.COUNT = 0
        else:
            self.COUNT = self.DIVISOR - 1

    def on_changes(self, ts, changes):
        # type: (int, Dict[str, int]) -> Optional[int]
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # Set attributes
        super(DivSimulation, self).on_changes(ts, changes)

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            if name in (NAMES.DIVISOR, NAMES.FIRST_PULSE):
                self.do_reset()

        # Reset on the falling edge of ENABLE or other register write
        if changes.get(NAMES.ENABLE, None) == 0:
            self.do_reset()
        elif NAMES.INP in changes:
            self.do_pulse(changes[NAMES.INP])

        return None
