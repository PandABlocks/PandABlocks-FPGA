from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING


if TYPE_CHECKING:
    from typing import Dict, Optional


NAMES, PROPERTIES = properties_from_ini(__file__, "clocks.block.ini")


class ClocksSimulation(BlockSimulation):
    A_PERIOD, B_PERIOD, C_PERIOD, D_PERIOD, OUTA, OUTB, OUTC, OUTD = \
        PROPERTIES

    def __init__(self):
        self.start_ts = 0

    def on_changes(self, ts, changes):
        # type: (int, Dict[str, int]) -> Optional[int]
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(ClocksSimulation, self).on_changes(ts, changes)
        if changes:
            # reset all clocks
            self.start_ts = ts
            for out in "ABCD":
                setattr(self, 'OUT' + out, 0)

        # decide if we need to produce any clocks
        next_ts = []
        for out in "ABCD":
            period = getattr(self, out + "_PERIOD")
            if period > 1:
                off = (ts - self.start_ts) % period
                half = period / 2
                # produce clock low level at start of period
                if off == 0:
                    setattr(self, 'OUT' + out, 0)
                    next_ts.append(ts + half)
                # produce clock low level at half period
                elif off == half:
                    setattr(self, 'OUT' + out, 1)
                    next_ts.append(ts - half + period)

        # now work out when next to make a pulse
        if next_ts:
            return min(next_ts)
        else:
            return None
