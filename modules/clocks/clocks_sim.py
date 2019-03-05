from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING


if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "clocks.block.ini")


class ClocksSimulation(BlockSimulation):
    ENABLE, PERIOD, OUT = PROPERTIES

    def __init__(self):
        self.start_ts = 0

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
        super(ClocksSimulation, self).on_changes(ts, changes)

        # If not enabled, stop the clocks
        if not self.ENABLE:
            self.OUT = 0
        else:
            if changes:
                # reset start time if PERIOD or ENABLE have changed
                self.start_ts = ts
            # decide if we need to produce any clocks
            if self.PERIOD > 1:
                off = (ts - self.start_ts) % self.PERIOD
                half = self.PERIOD / 2
                # produce clock high level at start of period
                if off == 0:
                    self.OUT = 1
                    return ts + half
                # produce clock low level at half period
                elif off == half:
                    self.OUT = 0
                    return ts - half + self.PERIOD
            else:
                self.OUT = 0

