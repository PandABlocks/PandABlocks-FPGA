from common.python.simulations import BlockSimulation, properties_from_ini

from collections import deque

# max queue size
MAX_QUEUE = 1023

# min FPGA deadtime between queued pulses
MIN_QUEUE_DELTA = 4

# time taken to clear queue
QUEUE_CLEAR_TIME = 4

NAMES, PROPERTIES = properties_from_ini(__file__, "pulse.block.ini")


class PulseSimulation(BlockSimulation):
    ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, TRIG_EDGE, OUT, QUEUED, \
        DROPPED = PROPERTIES

    def __init__(self):
        self.queue = deque()
        self.valid_ts = 0
        self.trigtime = 0
        self.enqueue = 0
        self.dequeue = 0
        self.delaypulse = 0
        self.delayqueue = 1
        self.doqueue = 0
        self.missedsignal = 0
        self.width = 0
        self.delay = 0

    def do_pulse(self, ts, changes):
        """We've received a bit event on INP, so queue some output values
        based on DELAY and WIDTH"""
        # If the queue isn't valid at the moment then error
        # If there isn't room for 2 on the queue then error
        # If WIDTH is zero DELAY should be >3, or if DELAY is zero WIDTH
        # should be >3 for the FIFO to iterate fully
        width = self.width
        delay = self.delay
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
            self.missedsignal += 1
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
        next_ts = ts+1
        # If the DELAY and WIDTH inputs are out of bounds, set them to 4

        if 0 < self.DELAY_L < 4:
            self.delay = 4
        else:
            self.delay = self.DELAY_L
        if (0 < self.WIDTH_L < 4) and self.DELAY_L == 0:
            self.width = 4
        else:
            self.width = self.WIDTH_L

        # Append queue if the start of the queue is delayed
        if self.delaypulse == 1:
            if self.WIDTH_L > 0 or self.doqueue == 1:
                self.QUEUED += 1
                self.delaypulse = 0
                self.doqueue = 0
            elif changes.get(NAMES.TRIG, None) == 0:
                self.doqueue = 1

        # Increment the queue
        if self.enqueue == 1 and ts == self.trigtime+1:
            if self.missedsignal > 0:
                self.missedsignal -= 1
            else:
                self.QUEUED += 1
            # Is a pulse of zero required before next pulse?
                if self.DELAY_L > 0:
                    self.delaypulse = 1
                self.enqueue = 0

        # On the trigger edge set the writestrobe to the queue
        # If both DELAY and WIDTH are equal to 0, the module bypasses the queue
        if self.width == 0 and self.delay == 0:
            self.enqueue = 0
        elif changes.get(NAMES.TRIG) == 1 and self.TRIG_EDGE in (0, 2):
            # Positive edge
            self.trigtime = ts
            self.enqueue = 1
        elif changes.get(NAMES.TRIG) == 0 and self.TRIG_EDGE in (1, 2):
            # Negative edge
            self.trigtime = ts + 1
            self.enqueue = 1

        # Set attributes, and flag clear queue
        for name, value in changes.items():
            setattr(self, name, value)
            if name in ("DELAY_L", "DELAY_L", "WIDTH_L", "WIDTH_L"):
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
            # next_ts = self.queue[0][0]
            # if the pulse on our queue is ready to be produced then produce
            if self.queue[0][0] == ts:
                if self.queue.popleft()[1] == 1:
                    self.OUT = 1
                    self.dequeue = 1
                else:
                    self.OUT = 0
            assert next_ts >= ts, "Going back in time %s >= %s" % (next_ts, ts)

        # At the end of the pulse, the queue count has decreased
        if self.OUT == 0 and self.dequeue == 1:
            if self.QUEUED > 0:
                self.QUEUED -= 1
            self.dequeue = 0
            self.delayqueue = 1

        # Decrease the queue count for the zero pulse
        if self.OUT == 1 and self.delayqueue == 1:
            if self.QUEUED > 0:
                self.QUEUED -= 1
            self.delayqueue = 0

        return next_ts
