from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "calc.block.ini")


class CalcSimulation(BlockSimulation):
    INPA, INPB, INPC, INPD, A, B, C, D, FUNC, OUT = PROPERTIES

    def __init__(self):
        self.scale = {0: 0, 1: 1, 2: 2}

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(CalcSimulation, self).on_changes(ts, changes)
        # This is a ConfigBlock object
        # b = self.config_block

        self.OUT = (self.INPA + self.INPB + self.INPC + self.INPD)\
            >> self.scale[self.FUNC]  # self.SCALE renamed to self.FUNC
        # moved above statement to before the FOR loop

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

            return ts+1
