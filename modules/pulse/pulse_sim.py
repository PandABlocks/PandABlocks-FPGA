from common.python.simulations import BlockSimulation, properties_from_ini

from collections import deque
from math import floor

# max queue size
MAX_QUEUE = 1023

# time taken to clear queue
QUEUE_CLEAR_TIME = 1

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
        # The current timestamp
        self.timestamp = 0
        # Any remaining delay
        self.delay_remaining = 0

        self.timestamp_rise = 0
        self.timestamp_fall = 0
        self.had_rising_trigger = 0
        self.had_falling_trigger = 0
        self.fancy_delay_line = 0
        self.delay_timestamp = 0
        self.internal_queue_length = 0


    def do_queue(self, ts, output_value):
        self.queue.append((ts, output_value))


    def do_clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.valid_ts = ts + QUEUE_CLEAR_TIME
        self.OUT = 0
        self.QUEUED = 0
        self.queue.clear()
        self.edges_remaining = 0
        self.ongoing_pulse = 0
        self.produced_width = 0


    def start_delay(self, ts, delay):
        if (self.delay_timestamp == 0):
            self.delay_timestamp = ts + delay
            self.first_word_dropthrough = 1


    def programmed_step_to_queue(self, pulses, ts, delay, gap, step, width):
        self.internal_queue_length += 1

        if (len(self.queue) == 0):
            ts -= 1
            self.do_queue(ts + delay, 2)

            for loopIter in range(pulses):
                self.do_queue(ts + delay + (step * loopIter), 1)
                self.do_queue(ts + delay + width + (step * loopIter), 0)
        else:
            lastTimestamp = self.queue[-1][0]
            self.do_queue(lastTimestamp + gap, 2)

            for loopIter in range(pulses):
                self.do_queue(lastTimestamp + gap + (step * loopIter), 1)
                self.do_queue(lastTimestamp + gap + width + (step * loopIter), 0)
            
        self.start_delay(ts, delay)


    def ts_to_queue(self, changes, ts, delay):
        self.internal_queue_length += 1

        if (len(self.queue) == 0):
            ts -= 1

        self.do_queue(ts + delay, 2)

        if (changes.get(NAMES.TRIG) == 1):
            self.do_queue(ts + delay, 1)
        if (changes.get(NAMES.TRIG) == 0):
            self.do_queue(ts + delay, 0)

        self.start_delay(ts, delay)


    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""

        # CHANGES = ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, STEP_L, STEP_H, TRIG_EDGE, OUT, QUEUED, DROPPED
        super(PulseSimulation, self).on_changes(ts, changes)


        ############################################
        # Freestanding counters, assignments, etc. #
        ############################################

        # Variable assignments from inputs
        delay = self.DELAY_L + (self.DELAY_H << 32)
        if delay < 5:
            delay = 6

        pulses = max(1, self.PULSES)

        width = self.WIDTH_L + (self.WIDTH_H << 32)

        step = self.STEP_L + (self.STEP_H << 32)
        if (step < width):
            step = step + width + 1

        gap = 0
        if ((step - width) > 1):
            gap = step - width
        else:
            gap = 1

        self.QUEUED = self.internal_queue_length


        ############################################
        #              Queue filling               #
        ############################################

        if (changes.get(NAMES.ENABLE) == 0):
            self.do_clear_queue(0)
        if (changes.get(NAMES.ENABLE) == 1):
            self.DROPPED = 0
            self.do_clear_queue(0)
        elif (self.ENABLE == 1):
            if(changes.get(NAMES.TRIG) == 1):
                self.timestamp_rise = ts
            if(changes.get(NAMES.TRIG) == 0):
                self.timestamp_fall = ts


            if (changes.get(NAMES.TRIG) != None):
                # Dropped edge conditions
                if ((self.fancy_delay_line == 0) and ((self.delay_timestamp != 0 and ts >= self.delay_timestamp))):
                    if  (
                            ((self.TRIG_EDGE == 0) and (changes.get(NAMES.TRIG) == 1)) or
                            ((self.TRIG_EDGE == 1) and (changes.get(NAMES.TRIG) == 0)) or
                            ((self.TRIG_EDGE == 2) and (changes.get(NAMES.TRIG) != None))
                        ):

                        self.DROPPED += 1

                # Fully pre-programmed
                elif (width != 0):
                    if  (
                            ((self.TRIG_EDGE == 0) and (changes.get(NAMES.TRIG) == 1)) or
                            ((self.TRIG_EDGE == 1) and (changes.get(NAMES.TRIG) == 0)) or
                            ((self.TRIG_EDGE == 2) and (changes.get(NAMES.TRIG) != None))
                        ):

                        self.programmed_step_to_queue(pulses, ts, delay, gap, step, width)

                # Part pre-programmed
                elif ((width == 0) and (self.STEP_L + (self.STEP_H << 32) != 0)):
                    if  ((self.TRIG_EDGE == 0) and (changes.get(NAMES.TRIG) == 1)):
                        if ((changes.get(NAMES.TRIG) == 1) and (self.had_rising_trigger == 0)):
                            self.had_rising_trigger = 1
                        elif ((changes.get(NAMES.TRIG) == 1) and (self.had_rising_trigger == 1)):
                            self.had_rising_trigger = 0
                            self.programmed_step_to_queue(pulses, ts, delay, gap, step, width)

                    if  ((self.TRIG_EDGE == 1) and (changes.get(NAMES.TRIG) == 0)):
                        if ((changes.get(NAMES.TRIG) == 1) and (self.had_falling_trigger == 0)):
                            self.had_falling_trigger = 1
                        elif ((changes.get(NAMES.TRIG) == 1) and (self.had_falling_trigger == 1)):
                            self.had_falling_trigger = 0
                            self.programmed_step_to_queue(pulses, ts, delay, gap, step, width)

                # Fully making it up
                elif ((width == 0) and (self.STEP_L + (self.STEP_H << 32) == 0)):
                    self.fancy_delay_line = 1

                    if (len(self.queue) != 0):
                        if (ts - (self.queue[-1][0] - delay) < 2):
                            self.DROPPED += 1
                        else:
                            self.ts_to_queue(changes, ts, delay)

                    else:
                        self.ts_to_queue(changes, ts, delay)


        ############################################
        #             Queue processing             #
        ############################################

        if (changes.get(NAMES.ENABLE) == 1):
            pass
            # in case we need to clear things

        elif ((self.ENABLE == 1) and (len(self.queue) != 0)):
            if ((ts, 2) in self.queue):
                self.queue.popleft()
                self.internal_queue_length -= 1
                self.QUEUED = self.internal_queue_length

            if ((ts, 1) in self.queue):
                self.queue.popleft()
                self.OUT = 1

            if ((ts, 0) in self.queue):
                self.queue.popleft()
                self.OUT = 0

            if ((len(self.queue)) == 0):
                self.delay_timestamp = 0

        else:
            self.OUT = 0
