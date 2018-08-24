from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

from collections import deque
# max queue size
MAX_QUEUE = 1023

if TYPE_CHECKING:
    from typing import Dict


# min FPGA deadtime between queued pulses
MIN_QUEUE_DELTA = 4

# time taken to clear queue
QUEUE_CLEAR_TIME = 4

NAMES, PROPERTIES = properties_from_ini(__file__, "pulse.block.ini")


class PulseSimulation(BlockSimulation):
    DELAY, WIDTH, ENABLE, TRIG, OUT, QUEUED, DROPPED, TRIG_EDGE = PROPERTIES

    def __init__(self):
        self.queue = deque()
        self.valid_ts = 0

    def do_pulse(self, ts, changes):
        """We've received a bit event on INP, so queue some output values
        based on DELAY and WIDTH"""
        # If the queue isn't valid at the moment then error
        # If there isn't room for 2 on the queue then error
        width = self.WIDTH
        delay = self.DELAY
        if ts < self.valid_ts or len(self.queue) + 2 > MAX_QUEUE:
            self.DROPPED += 1
        # If there is no specified width then use the width of input pulse
        elif width == 0:
            self.queue.append((ts + delay, self.TRIG))
        elif self.TRIG and self.TRIG_EDGE == 0:
            self.generate_queue(ts, delay, width)
        elif not self.TRIG and self.TRIG_EDGE == 1 and delay == 0:
            self.generate_queue(ts+1, delay, width)
        elif not self.TRIG and self.TRIG_EDGE == 1 and delay >= 0:
            self.generate_queue(ts, delay, width)
        elif self.TRIG and self.TRIG_EDGE == 2:
            self.generate_queue(ts, delay, width)
        elif not self.TRIG and self.TRIG_EDGE == 2:
            self.generate_queue(ts, delay+1, width)

    def generate_queue(self, ts, delay, width):
        # generate both high and low queue from inp
        start = ts + delay
        # make sure that start is after any pulse on queue
        if self.queue and start < self.queue[-1][0] + MIN_QUEUE_DELTA:
            self.DROPPED += 1
        else:
            self.queue.append((start, 1))
            self.queue.append((start + width, 0))

    def do_reset(self):
        """Reset the block, called on rising edge of ENABLE"""
        self.DROPPED = 0

    def do_clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.valid_ts = ts + QUEUE_CLEAR_TIME
        self.OUT = 0
        self.queue.clear()

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        super(PulseSimulation, self).on_changes(ts, changes)
        # This is the next time we need to be called
        next_ts = None

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)
            if name in (NAMES.DELAY, NAMES.DELAY, NAMES.WIDTH, NAMES.WIDTH):
                self.do_clear_queue(ts)

        # On rising edge of enable clear errors
        if changes.get(NAMES.ENABLE, None) == 1:
            self.do_reset()
        # on falling edge of enable reset output and queue
        elif changes.get(NAMES.ENABLE, None) == 0:
            self.do_clear_queue(ts)

        # If we got an input and we were enabled then output a pulse
        if NAMES.TRIG in changes and self.ENABLE:
            self.do_pulse(ts, changes)

        # if we have anything else on the queue return when it's due
        if self.queue:
            next_ts = self.queue[0][0]
            # if the pulse on our queue is ready to be produced then produce
            if self.queue[0][0] == ts:
                self.OUT = self.queue.popleft()[1]
            assert next_ts >= ts, "Going back in time %s >= %s" % (next_ts, ts)

        # Event list changed, update status word
        self.QUEUED = len(self.queue)
        return next_ts
