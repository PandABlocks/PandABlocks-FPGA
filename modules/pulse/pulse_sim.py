from common.python.simulations import BlockSimulation, properties_from_ini

from collections import deque

# Max queue size
MAX_QUEUE = 255

# Time taken to get through queue
QUEUE_DELAY = 4

NAMES, PROPERTIES = properties_from_ini(__file__, "pulse.block.ini")


class PulseSimulation(BlockSimulation):
    ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, \
        STEP_L, STEP_H, TRIG_EDGE, OUT, QUEUED, DROPPED = PROPERTIES

    def __init__(self):
        # Whether we were enabled last clock tick
        self.was_enabled = False
        # When to produce the next edge
        self.edge_ts = 0
        # How many edges left to produce
        self.edges_remaining = 0
        # When we made a pulse, when is the next valid pulses
        self.acceptable_pulse_ts = 0
        # This mimicks the VHDL pulse_queue, filled with a maximum of one entry
        # each clock tick, and consumed at the correct ts to make self.OUT
        self.queue = deque()

    def do_queue(self, ts, level):
        self.queue.append((ts, level))

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(PulseSimulation, self).on_changes(ts, changes)

        # When we will next be called
        next_ts = None

        # This is what we will set the output to
        out = self.OUT

        # Validation of input parameters
        width = self.WIDTH_L + (self.WIDTH_H << 32)
        delay = self.DELAY_L + (self.DELAY_H << 32)
        step = self.STEP_L + (self.STEP_H << 32)
        if 0 < width < 5:
            width = 5
        if 0 < delay < 5:
            delay = 5
        if step <= width:
            step = width + 1
        pulses = max(1, self.PULSES)

        # Calculation of enable signal
        is_enabled = changes.get(NAMES.ENABLE, self.ENABLE) == 1
        clear_if = {NAMES.DELAY_L, NAMES.DELAY_H, NAMES.WIDTH_L, NAMES.WIDTH_H,
                    NAMES.STEP_L, NAMES.STEP_H, NAMES.PULSES, NAMES.TRIG_EDGE}
        if clear_if.intersection(changes):
            # Something was changed,
            is_enabled = False
            next_ts = ts + 1
        enabled_rise = is_enabled and not self.was_enabled
        self.was_enabled = is_enabled

        # Calculation of trigger signal
        if NAMES.TRIG in changes:
            got_trigger = (self.TRIG_EDGE == 0 and self.TRIG) or \
                          (self.TRIG_EDGE == 1 and not self.TRIG) or \
                           self.TRIG_EDGE == 2 or width == 0
        else:
            got_trigger = False

        # Set from the length of the queue
        queued = len(self.queue)

        # Queue producing process
        if enabled_rise:
            self.edge_ts = 0
        elif is_enabled and self.edges_remaining:
            if ts == self.edge_ts:
                if self.edges_remaining % 2:
                    out = 0
                    self.edge_ts = ts + step - width
                else:
                    out = 1
                    self.edge_ts = ts + width
                self.edges_remaining -= 1
                if not self.edges_remaining:
                    # Done with pulse
                    self.queue.popleft()
                    queued -= 1
        elif is_enabled and self.queue and ts == self.queue[0][0]:
            if width == 0:
                out = self.queue.popleft()[1]
                queued -= 1
            else:
                out = 1
                # Not just a delay line, need more edges
                self.edges_remaining = 2*pulses - 1
                self.edge_ts = ts + width
                if delay == 0:
                    # We added 4 ticks to account for queue delays, subtract it
                    self.edge_ts -= QUEUE_DELAY
        elif not is_enabled:
            out = 0
            self.edges_remaining = 0
            self.queue.clear()
            queued = 0

        # Queue filling process
        if enabled_rise:
            self.DROPPED = 0
            self.acceptable_pulse_ts = 0
        elif is_enabled and got_trigger:
            if ts < self.acceptable_pulse_ts or len(self.queue) > MAX_QUEUE:
                self.DROPPED += 1
            elif width == 0:
                if delay == 0:
                    out = self.TRIG
                else:
                    self.do_queue(ts + delay, self.TRIG)
            else:
                if delay == 0:
                    out = 1
                    self.do_queue(ts + QUEUE_DELAY, 1)
                else:
                    self.do_queue(ts + delay, 1)
                self.acceptable_pulse_ts = ts + step * pulses - step + width + 1

        # Set outputs and return when next called
        self.OUT = out
        self.QUEUED = queued

        # If we now have edges_remaining, or if we didn't update the queue
        # yet then we need to process then next clock tick
        if len(self.queue) != self.QUEUED:
            next_ts = ts + 1
        elif self.queue and self.queue[0][0] > ts:
            if next_ts is None or self.queue[0][0] < next_ts:
                next_ts = self.queue[0][0]
        return next_ts
