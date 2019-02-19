from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING


if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "clocks.block.ini")


class ClocksSimulation(BlockSimulation):
    ENABLE, A_PERIOD, B_PERIOD, C_PERIOD, D_PERIOD, OUTA, OUTB, OUTC, OUTD = \
        PROPERTIES

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
            self.OUTA = 0
            self.OUTB = 0
            self.OUTC = 0
            self.OUTD = 0
        else:
            if changes:
                # reset all clocks
                self.start_ts = ts
                for out in "ABCD":
                    if getattr(self, out + '_PERIOD') > 1:
                        val = 1
                    else:
                        val = 0
                    setattr(self, 'OUT' + out, val)

            # decide if we need to produce any clocks
            next_ts = []
            for out in "ABCD":
                period = getattr(self, out + "_PERIOD")
                if period > 1:
                    off = (ts - self.start_ts) % period
                    half = period / 2
                    # produce clock high level at start of period
                    if off == 0:
                        setattr(self, 'OUT' + out, 1)
                        next_ts.append(ts + half)
                    # produce clock low level at half period
                    elif off == half:
                        setattr(self, 'OUT' + out, 0)
                        next_ts.append(ts - half + period)
                    # Work out when we next need to be called
                    if off < half:
                        # Called at half period
                        next_ts.append(ts - off + half)
                    else:
                        # Called at full period
                        next_ts.append(ts - off + period)
            # now work out when next to make a pulse
            if next_ts:
                return min(next_ts)

