from .block import Block


class Clocks(Block):
    def __init__(self):
        self.start_ts = 0

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        if changes:
            for name, value in changes.items():
                setattr(self, name, value)
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
