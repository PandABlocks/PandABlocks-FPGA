from .block import Block
from .event import Event


class Clocks(Block):

    def __init__(self, num):
        super(Clocks, self).__init__(num)
        self.start_ts = 0

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
            # reset all clocks
            self.start_ts = event.ts
            for out in "ABCD":
                bus_index = getattr(self, out)
                next_event.bit[bus_index] = 0
        # decide if we need to produce any clocks
        next_ts = []
        for out in "ABCD":
            period = getattr(self, out + "_PERIOD")
            bus_index = getattr(self, out)
            if period > 1:
                off = (event.ts - self.start_ts) % period
                half = period / 2
                # produce clock high level
                if off == 0:
                    next_event.bit[bus_index] = 0
                    next_ts.append(event.ts + half)
                # produce clock low level
                elif off == half:
                    next_event.bit[bus_index] = 1
                    next_ts.append(event.ts - half + period)
        # now work out when next to make a pulse
        if next_ts:
            next_event.ts = min(next_ts)
        # return any changes and next ts
        return next_event
