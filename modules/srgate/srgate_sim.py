from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


RISING = 0
FALLING = 1
EITHER = 2

NAMES, PROPERTIES = properties_from_ini(__file__, "srgate.block.ini")


class SrgateSimulation(BlockSimulation):
    WHEN_DISABLED, SET_EDGE, RST_EDGE, FORCE_SET, FORCE_RST, ENABLE, SET, \
        RST, OUT = PROPERTIES

    def inp_matches_edge(self, inp, edge):
        if edge == RISING and inp == 1 or edge == FALLING and inp == 0 \
                or edge == EITHER and inp is not None:
            return True

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(SrgateSimulation, self).on_changes(ts, changes)

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # If enabled listen to inputs
        if self.ENABLE:
            # Force regs take priority
            if NAMES.FORCE_RST in changes:
                self.OUT = 0
            elif NAMES.FORCE_SET in changes:
                self.OUT = 1
            elif self.inp_matches_edge(changes.get(NAMES.RST, None),
                                       self.RST_EDGE):
                self.OUT = 0
            elif self.inp_matches_edge(changes.get(NAMES.SET, None),
                                       self.SET_EDGE):
                self.OUT = 1
        else:
            # Set output to what has been requested when disabled
            if self.WHEN_DISABLED == 0:
                self.OUT = 0
            elif self.WHEN_DISABLED == 1:
                self.OUT = 1
