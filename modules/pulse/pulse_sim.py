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
        # This mimicks the VHDL pulse_queue, filled with a maximum of one entry
        # each clock tick, and consumed at the correct ts to make self.OUT
        self.queue = deque()
        # Whenever we get a pulse, if the timestamp is less that this then
        # ignore it
        self.valid_ts = 0
        # This is to flag we are currently producing a pulse
        self.ongoing_pulse = 0
        # This is when we produced a rising edge
        self.rising_ts = 0
        # This is the number of edges remaining to produce
        self.edges_remaining = 0
        # This is the pulse width we should produce
        self.produced_width = 0

    def do_queue(self, ts, level):
        self.queue.append((ts, level))

    def do_reset(self):
        """Reset the block, called on rising edge of ENABLE"""
        self.DROPPED = 0

    def do_clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.valid_ts = ts + QUEUE_CLEAR_TIME
        self.OUT = 0
        self.QUEUED = 0
        self.queue.clear()
        self.edges_remaining = 0
        self.ongoing_pulse = 0
        self.produced_width = 0

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
            # This is the value self.OUT will be set to at the end
            out = self.OUT

            # if we have an pulse on our queue that is due, produce it
            if self.queue and self.queue[0][0] == ts:
                # generate output value
                out = self.queue.popleft()[1]

            # if we have anything else on the queue, return when it's due
            if self.queue:
                next_ts = self.queue[0][0]
                assert next_ts >= ts, "Going back in time %s >= %s" % (
                    next_ts, ts)

            # Event list size is registered one clock tick later
            self.QUEUED = len(self.queue)

            # Work out if we need to produce a rising edge or falling edge
            if NAMES.TRIG in changes:
                trig_rise = (self.TRIG_EDGE == 0 and self.TRIG) or \
                            (self.TRIG_EDGE == 1 and not self.TRIG) or \
                            self.TRIG_EDGE == 2
                trig_fall = not trig_rise
            else:
                trig_rise = False
                trig_fall = False

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
            pulses = max(1, self.PULSES)
            step = max(self.STEP_L + (self.STEP_H << 32),
                       width + MIN_QUEUE_DELTA)
            queue_full = len(self.queue) + 2 > MAX_QUEUE

            if self.produced_width and self.edges_remaining:
                # Queue any pulses that are still pending
                pulse_index = pulses - (self.edges_remaining + 1) // 2
                pulse_start = self.rising_ts + delay + pulse_index * step
                if self.edges_remaining % 2:
                    # Produce low level
                    self.do_queue(pulse_start + self.produced_width, 0)
                else:
                    # Produce high level
                    self.do_queue(pulse_start, 1)
                self.edges_remaining -= 1
                # If we needed to produce a rising edge, drop it
                if trig_rise:
                    self.DROPPED += 1
            # If we got a pulse that won't fit, error
            elif trig_rise and (ts < self.valid_ts or queue_full):
                self.DROPPED += 1
            elif trig_rise:
                if delay == 0:
                    # Produce pulse now
                    out = 1
                    if width != 0:
                        # Queue falling edge
                        self.do_queue(ts + delay + width, 0)
                        # We already made the first rising and falling edges
                        # the rest are still needed
                        self.edges_remaining = 2 * pulses - 2
                else:
                    # Queue rising edge
                    self.do_queue(ts + delay, 1)
                    # We already made the rising edge, the rest are still needed
                    self.edges_remaining = 2 * pulses - 1
                # Store that we are currently outputting a pulse and when it
                # started
                self.ongoing_pulse = 1
                self.produced_width = width
                self.rising_ts = ts
                if width != 0:
                    # Can't get another pulse until we produced the falling edge
                    self.valid_ts = self.rising_ts + (pulses - 1) * step \
                        + width + MIN_QUEUE_DELTA
            elif trig_fall and self.ongoing_pulse and width == 0:
                if delay == 0:
                    # Bypass the queue, produce it straight away
                    out = 0
                else:
                    # Queue the falling edge now
                    self.do_queue(ts + delay + width, 0)
                # We have made the first rising and falling edge, so queue the
                # rest
                self.edges_remaining = 2 * pulses - 2
                # Say that we have stopped outputting a pulse
                self.ongoing_pulse = 0
                self.produced_width = ts - self.rising_ts
                # Can't get another pulse until we produced the falling edge
                self.valid_ts = self.rising_ts + (pulses - 1) * step \
                    + width + MIN_QUEUE_DELTA

            # If we now have edges_remaining, or if we didn't update the queue
            # yet then we need to process then next clock tick
            if len(self.queue) != self.QUEUED or (
                    self.edges_remaining and self.produced_width):
                next_ts = ts + 1

            # Set the output, which might have been set from the queue, or
            # might be produced straight through
            self.OUT = out

        return next_ts
