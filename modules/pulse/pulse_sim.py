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
        self.timestamp = 0

        self.queue = deque()
        self.queue_full = False
        self.queue_output = 0
        self.queue_timestamp = 0
        self.out_from_queue = False
        self.last_queue_length = 0

        self.timestamp = 0

        self.pulses_i = 0
        self.delay_i = 0
        self.gap_i = 0
        self.step_i = 0
        self.width_i = 0
        self.trig_edge = 0

        self.trig_fall = False
        self.trig_rise = False
        self.trig_same = True
        self.previous_trigger = 0

        self.next_acceptable_pulse_ts = 0
        self.override_ends_ts = 0
        self.edges_remaining = 0
        self.pulse_timestamp = 0
        self.missed_pulses = 0
        self.previous_enable = False

        self.pulse_override = False
        self.dropped_flag = False

        self.queue_decrements_left = 0
        self.queue_increment_timestamps = deque()

    def incoming_changes(self, changes):
        for name, value in changes.items():
            setattr(self, name, value)

        
    def edge_validation(self, rise_value, fall_value, edge_value):
        if (((edge_value == 0) and (rise_value == 1)) or
            ((edge_value == 1) and (fall_value == 1)) or
             (edge_value == 2) 
           ):
            return True
        else:
            return False


    def delay_and_blocking_validation(self, delay_i, overall_time, pulses_i, width_i, timestamp, rise_value, fall_value, edge_value):
        if (self.edge_validation(rise_value, fall_value, edge_value)):
            if (delay_i == 0):
                self.pulse_override = True
                self.override_ends_ts = timestamp + width_i

            if (pulses_i == 1):
                self.next_acceptable_pulse_ts = timestamp + width_i
            else:
                self.next_acceptable_pulse_ts = timestamp + overall_time


    def external_variable_internal_configuration(self):
        # Variable assignments from inputs

        if ((self.DELAY_L != None) and (self.DELAY_H != None)):
            delay = self.DELAY_L + (self.DELAY_H << 32)
        elif (self.DELAY_L != None):
            delay = self.DELAY_L
        else:
            delay = 0

        if ((self.STEP_L != None) and (self.STEP_H != None)):
            step = self.STEP_L + (self.STEP_H << 32)
        elif (self.STEP_L != None):
            step = self.STEP_L
        else:
            step = 0

        if ((self.WIDTH_L != None) and (self.WIDTH_H != None)):
            width = self.WIDTH_L + (self.WIDTH_H << 32)
        elif (self.WIDTH_L != None):
            width = self.WIDTH_L
        else:
            width = 0

        self.pulses_i = max(1, self.PULSES)

        if ((width > 5) or (width == 0)):
            self.width_i = width
        else:
            self.width_i = 6    

        if ((delay > 5) or ((width != 0) and (delay == 0)) or ((width == 0) and (delay > 5))):
            self.delay_i = delay
        else:
            self.delay_i = 6

        if ((step > self.width_i) or (step == 0)):
            self.step_i = step
        else:
            self.step_i = self.width_i + 1

        if ((step - width) > 1):
            self.gap_i = (self.step_i - self.width_i)
        else:
            self.gap_i = 1

        self.overall_time = (self.pulses_i * self.step_i) - self.gap_i


    def edge_detection(self, incoming_trigger):
        if (self.ENABLE == False):
            self.dropped_flag = False
            self.pulse_override = False
            self.next_acceptable_pulse_ts = 0
            self.override_ends_ts = 0

        else:
            fall_trig = False
            rise_trig = False
            same_trig = False
            self.dropped_flag = False

            if   ((incoming_trigger == False) and (incoming_trigger != self.previous_trigger)):
                fall_trig = True
            elif ((incoming_trigger == True) and (incoming_trigger != self.previous_trigger)):
                rise_trig = True
            elif (incoming_trigger == self.previous_trigger):
                same_trig = True

            if (same_trig != True):
                if (self.timestamp < self.next_acceptable_pulse_ts):
                    if (self.edge_validation(rise_trig, fall_trig, self.TRIG_EDGE)):
                        self.dropped_flag = True
                else:
                    self.delay_and_blocking_validation(self.delay_i, self.overall_time, self.pulses_i, self.width_i, self.timestamp, rise_trig, fall_trig, self.TRIG_EDGE)

            if (self.timestamp == self.override_ends_ts):
                self.pulse_override = False

            self.trig_fall = fall_trig
            self.trig_rise = rise_trig
            self.trig_same = same_trig

        self.previous_trigger = incoming_trigger
        self.previous_enable = self.ENABLE


    def queue_filling(self):
        if (self.ENABLE == False):
            self.clear_queue()
            self.missed_pulses = 0
            self.timestamp_to_queue = 0

        else:
            if (self.dropped_flag == True):
                self.missed_pulses += 1

            elif (self.trig_same == False):
                timestamp_to_queue = self.timestamp + self.delay_i - 1

                if (self.queue_full == True):
                    self.missed_pulses += 1
                    self.dropped_flag = False

                elif (self.width_i == 0):
                    if(self.trig_rise == True):
                        self.append_to_queue(1, timestamp_to_queue)
                    else:
                        self.append_to_queue(0, timestamp_to_queue)
                else:
                    if(self.edge_validation(self.trig_rise, self.trig_fall, self.TRIG_EDGE)):
                        self.append_to_queue(1, timestamp_to_queue)
                    


    def process_queue(self):
        if (self.ENABLE == False):
            self.out_from_queue = False
        else:
            if (len(self.queue) == 1):
                self.queue_output, self.queue_timestamp = self.queue[0]

            if (self.width_i == 0):
                if (self.timestamp == self.queue_timestamp):
                    self.out_from_queue = self.queue_output
                    self.fetch_from_queue()
            else:
                if (self.pulses_i == 1):
                    if ((self.delay_i == 0) and (self.timestamp != 0)):
                        if ((self.timestamp == self.queue_timestamp + 5) and (len(self.queue) != 0)):
                            self.fetch_from_queue()

                    if ((self.delay_i == 0) and (len(self.queue) != 1) and (len(self.queue) != 0)):
                        self.fetch_from_queue()

                    elif ((self.timestamp == self.queue_timestamp) and (self.queue_timestamp != 0)):
                        self.out_from_queue = 1
                        self.pulse_timestamp = self.timestamp + self.width_i
                        self.fetch_from_queue()

                    elif (self.timestamp == self.pulse_timestamp):
                        self.out_from_queue = 0
                else:
                    if (self.edges_remaining != 0):
                        if (self.timestamp == self.pulse_timestamp):
                            if (self.edges_remaining % 2):
                                self.edges_remaining -= 1
                                self.pulse_timestamp = self.timestamp + self.gap_i
                                self.out_from_queue = int(not bool(self.out_from_queue))
                            else:
                                self.edges_remaining -= 1
                                self.pulse_timestamp = self.timestamp + self.width_i
                                self.out_from_queue = int(not bool(self.out_from_queue))

                            if (self.edges_remaining == 1):
                                self.fetch_from_queue()
                    else:
                        if (self.queue_timestamp != 0):
                            if ((self.delay_i == 0) and ((self.timestamp - 6) == self.queue_timestamp)):
                                self.pulse_timestamp = self.timestamp + self.gap_i + 1
                                self.edges_remaining = (self.pulses_i * 2) - 2

                            elif (self.timestamp == self.queue_timestamp):
                                self.pulse_timestamp = self.timestamp + self.width_i
                                self.edges_remaining = (self.pulses_i * 2) - 1
                                self.out_from_queue = 1

    def append_to_queue(self, out_value, timestamp):
        self.queue.append((out_value, timestamp))
        self.queue_increment_timestamps.append(self.timestamp + 2)


    def fetch_from_queue(self):
        self.queue.popleft()
        self.queue_decrements_left += 1

        if (len(self.queue) != 0):
            self.queue_output, self.queue_timestamp = self.queue[0]



    def clear_queue(self):
        """Clear the queue, but not any errors"""
        self.queue.clear()
        self.queue_full = False



    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""

        # CHANGES = ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, STEP_L, STEP_H, TRIG_EDGE, OUT, QUEUED, DROPPED
        super(PulseSimulation, self).on_changes(ts, changes)
        self.timestamp = ts

        # INCOMING CHANGES: ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, STEP_L, STEP_H, TRIG_EDGE
        # OUTGOING CHANGES:  OUT, QUEUED, DROPPED

        self.DROPPED = self.missed_pulses
        queued = self.QUEUED

        if (self.previous_enable == False):
            queued = 0

        if (self.queue_decrements_left != 0):
            queued -= 1
            self.queue_decrements_left -= 1


        ############################################
        #     Load incoming changes into class     #
        ############################################

        self.incoming_changes(changes)        


        ############################################
        # Freestanding counters, assignments, etc. #
        ############################################

        self.external_variable_internal_configuration()


        ############################################
        #          Trigger edge detection          #
        ############################################

        self.edge_detection(self.TRIG)


        ############################################
        #              Queue filling               #
        ############################################

        self.queue_filling()


        ############################################
        #             Queue processing             #
        ############################################

        self.process_queue()


        ############################################
        #          Final output parameters         #
        ############################################

        if (self.ENABLE == False):
            self.queue_increment_timestamps.clear()
        else:
            if (len(self.queue_increment_timestamps) != 0):
                if (self.timestamp == self.queue_increment_timestamps[0]):
                    self.queue_increment_timestamps.popleft()
                    queued += 1

        if ((self.pulse_override == True) or (self.out_from_queue == True)):
            self.OUT = 1
        else:
            self.OUT = 0

        self.QUEUED = queued

        next_ts = self.timestamp + 1

        return next_ts
