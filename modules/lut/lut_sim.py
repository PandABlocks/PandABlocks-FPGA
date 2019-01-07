from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


VALUE = 0
RISING = 1
FALLING = 2
EITHER = 3


NAMES, PROPERTIES = properties_from_ini(__file__, "lut.block.ini")


class LutSimulation(BlockSimulation):
    INPA, INPB, INPC, INPD, INPE, TYPEA, TYPEB, TYPEC, TYPED, TYPEE, FUNC, OUT = PROPERTIES

    def calc_value(self, letter, changes):
        source = getattr(self, "TYPE" + letter)
        inp = "INP%s" % letter
        if source == VALUE:
            return getattr(self, inp)
        elif source == RISING:
            return int(changes.get(inp, None) == 1)
        elif source == FALLING:
            return int(changes.get(inp, None) == 0)
        else:
            return int(inp in changes)

    def on_changes(self, ts, changes):
        """Handle field changes at a particular timestamp

        Args:
            ts (int): The timestamp the changes occurred at
            changes (Dict[str, int]): Fields that changed with their value

        Returns:
             If the Block needs to be called back at a particular ts then return
             that int, otherwise return None and it will be called when a field
             next changes
        """
        # Set attributes
        super(LutSimulation, self).on_changes(ts, changes)

        # Calculate the values from inputs
        a = self.calc_value("A", changes)
        b = self.calc_value("B", changes)
        c = self.calc_value("C", changes)
        d = self.calc_value("D", changes)
        e = self.calc_value("E", changes)

        # The row of our truth table is is calculated by treating 0bABCDE as a
        # binary number with A as MSB and E as LSB
        row = (a << 4) + (b << 3) + (c << 2) + (d << 1) + e
        # We then shift the 32-bit FUNC to get the right row in the LSB, and
        # extract this as self.OUT
        self.OUT = (self.FUNC >> row) & 1

        # We might have produced a pulse if anything has changed so call
        # back next clock tick just in case
        if changes:
            return ts + 1
