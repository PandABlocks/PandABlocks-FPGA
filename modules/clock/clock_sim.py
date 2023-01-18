from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING


if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "clock.block.ini")


class ClockSimulation(BlockSimulation):
    ENABLE, PERIOD, WIDTH, OUT = PROPERTIES

    def __init__(self):
        self.start_ts = 0
        self.full_period = 0
        self.high_period = 0

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
        super(ClockSimulation, self).on_changes(ts, changes)

        # If not enabled, stop the clocks
        if not self.ENABLE or (not self.WIDTH and not self.PERIOD):
            self.OUT = 0
        else:
            if changes:
                # reset start time if WIDTH, PERIOD or ENABLE have changed
                self.start_ts = ts
            # set clock's pull period
            if self.PERIOD < self.WIDTH:
                self.full_period = self.WIDTH + 1
            elif self.PERIOD < 2:
                self.full_period = 2
            else:
                self.full_period = self.PERIOD
            # set clock's high period
            if self.WIDTH == 0:
                self.high_period = self.full_period // 2
            else:
                self.high_period = self.WIDTH
            # prepare to produce clocks
            off = (ts - self.start_ts) % self.full_period
            # produce clock high level at start of period
            if off == 0:
                self.OUT = 1
                return ts + self.high_period
            # produce clock low level at end of high period
            elif off == self.high_period:
                self.OUT = 0
                return ts - self.high_period + self.full_period

