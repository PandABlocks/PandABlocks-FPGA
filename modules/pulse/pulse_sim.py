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
    ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, \
        STEP_L, STEP_H, TRIG_EDGE, OUT, QUEUED, DROPPED = PROPERTIES

    def __init__(self):
        # This will be filled immediately with all the edges (only in Python)
        self.edge_queue = deque()
        # This mimicks the VHDL pulse_queue, filled from self.edge_queue once
        # a clock tick, and consumed at the correct ts to make self.OUT
        self.queue = deque()
        # Whenever we get a pulse, if the timestamp is less that this then
        # ignore it
        self.valid_ts = 0
        # This is to flag we are currently producing a pulse
        self.ongoing_pulse = 0
        # This is when we produced a rising edge
        self.rising_ts = 0

    def do_pulse(self, ts):
        """We've received a bit event on INP, so queue some output values
        based on DELAY and WIDTH"""
        # If the queue isn't valid at the moment then error
        # If there isn't room for 2 on the queue then error
        # If WIDTH is zero DELAY should be >3, or if DELAY is zero WIDTH
        # should be >3 for the FIFO to iterate fully
        width = self.WIDTH_L + (self.WIDTH_H << 32)
        delay = self.DELAY_L + (self.DELAY_H << 32)
        if 0 < delay < 4:
            delay = 4
        if delay == 0 and 0 < width < 4:
            width = 4

        trig_rise = (self.TRIG_EDGE == 0 and self.TRIG) or \
            (self.TRIG_EDGE == 1 and not self.TRIG) or self.TRIG_EDGE == 2
        # Sufficient here as we are only called when self.TRIG changes...
        trig_fall = not trig_rise
        queue_full = len(self.queue) + 2 > MAX_QUEUE

        # If we got a pulse that won't fit, error
        if trig_rise and (ts < self.valid_ts or queue_full):
            self.DROPPED += 1
        elif trig_rise:
            if delay == 0:
                # Bypass the queue, produce it straight away
                self.OUT = 1
            else:
                # Queue the rising edge
                self.do_queue(ts + delay, 1)
            if width != 0:
                # Queue the falling edge and any repeats now
                self.do_queue(ts + delay + width, 0)
                self.do_repeats(ts, delay, width)
            # Store that we are currently outputting a pulse and when it started
            self.ongoing_pulse = 1
            self.rising_ts = ts
        elif trig_fall and self.ongoing_pulse and width == 0:
            if delay == 0:
                # Bypass the queue, produce it straight away
                self.OUT = 0
            else:
                # Queue the falling edge now
                self.do_queue(ts + delay + width, 0)
            # Queue any repeats
            self.do_repeats(self.rising_ts, delay, ts - self.rising_ts)
            # Say that we have stopped outputting a pulse
            self.ongoing_pulse = 0

    def do_queue(self, ts, level):
        self.edge_queue.append((ts, level))

    def do_repeats(self, start_ts, delay, width):
        step = max(self.STEP_L + (self.STEP_H << 32), width + MIN_QUEUE_DELTA)
        pulses = max(1, self.PULSES)
        for i in range(1, pulses):
            self.do_queue(start_ts + delay + i * step, 1)
            self.do_queue(start_ts + delay + i * step + width, 0)
        # Can't get another pulse until we produced the falling edge
        self.valid_ts = start_ts + (pulses - 1) * step + width + MIN_QUEUE_DELTA

    def do_reset(self):
        """Reset the block, called on rising edge of ENABLE"""
        self.DROPPED = 0

    def do_clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.valid_ts = ts + QUEUE_CLEAR_TIME
        self.OUT = 0
        self.QUEUED = 0
        self.queue.clear()
        self.edge_queue.clear()

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(PulseSimulation, self).on_changes(ts, changes)

        # This is the next time we need to be called
        next_ts = None

        # flag clear queue if settings change or on falling ENABLE
        clear_if = {NAMES.DELAY_L, NAMES.DELAY_H, NAMES.WIDTH_L, NAMES.WIDTH_H,
                    NAMES.STEP_L, NAMES.STEP_H, NAMES.PULSES, NAMES.TRIG_EDGE}
        if (clear_if.intersection(changes) and self.ENABLE) \
                or changes.get(NAMES.ENABLE, None) == 0:
            self.do_clear_queue(ts)
        # On rising edge of enable clear errors
        elif changes.get(NAMES.ENABLE, None) == 1:
            self.do_reset()

        if self.ENABLE:
            # if the input changed, produce a pulse
            if NAMES.TRIG in changes:
                self.do_pulse(ts)

            # if we have an pulse on our queue that is due, produce it
            if self.queue and self.queue[0][0] == ts:
                # generate output value
                self.OUT = self.queue.popleft()[1]

            # if we have anything else on the queue, return when it's due
            if self.queue:
                next_ts = self.queue[0][0]

            # Event list changed, update status word
            self.QUEUED = len(self.queue)

            # tick any items that were produced last time onto the queue
            if self.edge_queue:
                self.queue.append(self.edge_queue.popleft())

        if next_ts:
            assert next_ts >= ts, "Going back in time %s >= %s" % (next_ts, ts)
            return next_ts
        elif self.edge_queue:
            # Nothing on the queue, but still pulses to tick out
            return ts + 1
