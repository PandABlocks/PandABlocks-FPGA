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

        has_reset = (clear_if.intersection(changes) and self.ENABLE) or changes.get(NAMES.ENABLE, None) == 0

        if has_reset:
            self.do_clear_queue(ts)
        # On rising edge of enable clear errors
        elif changes.get(NAMES.ENABLE, None) == 1:
            self.DROPPED = 0

        if self.ENABLE:
            # This is the value self.OUT will be set to at the end
            out = self.OUT

 			# Set up the input variables
            delay = self.DELAY_L + (self.DELAY_H << 32)
            pulses = max(1, self.PULSES)
            width = self.WIDTH_L + (self.WIDTH_H << 32)

            step = self.STEP_L + (self.STEP_H << 32)

            if (step < width)
            	step + width + 1
            
            if ((step - width) > 1)
            	gap = step - width
            else
            	gap = 1


            if ((step = 0) and (width = 0))
            	if self.queue and self.queue[0][0] == ts:
            	    # generate output value
            	    out = self.queue.popleft()[1]
            	








        if next_ts:
            assert next_ts >= ts, "Going back in time %s >= %s" % (next_ts, ts)
            return next_ts
