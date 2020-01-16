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

        self.pulse_queue = deque()
        self.pulse_queue_full = False
        self.queue_output = 0
        self.queue_timestamp = 0

        self.timestamp = 0

        self.delay_i = 0
        self.gap_i = 0
        self.step_i = 0
        self.width_i = 0
        self.trig_edge = 0

        self.trig_fall = False
        self.trig_rise = False
        self.trig_same = True

        self.next_acceptable_pulse_ts = 0
        self.override_ends_ts = 0
        self.edges_remaining = 0
        self.pulse_timestamp = 0
        self.missed_pulses = 0

        self.pulse_override = False
        self.dropped_flag = False


    def self.incoming_changes(self, changes):
        self.ENABLE = changes.get(NAMES.ENABLE)
        self.TRIG = changes.get(NAMES.TRIG)
        self.DELAY_L = changes.get(NAMES.DELAY_L)
        self.DELAY_H = changes.get(NAMES.DELAY_H)
        self.WIDTH_L = changes.get(NAMES.WIDTH_L)
        self.WIDTH_H = changes.get(NAMES.WIDTH_H)
        self.PULSES = changes.get(NAMES.PULSES)
        self.STEP_L = changes.get(NAMES.STEP_L)
        self.STEP_H = changes.get(NAMES.STEP_H)
        self.TRIG_EDGE = changes.get(NAMES.TRIG_EDGE)
        

    def self.outgoing_changes(self, changes):
        

        return changes

        
    def edge_validation(self, rise_value, fall_value, edge_value):
        if (((edge_value == 0) and (rise_value == 1)) or
            ((edge_value == 1) and (fall_value == 1)) or
             (edge_value == 2) 
           ):
            return True
        else
            return False


    def delay_and_blocking_validation(self, delay_i, gap_i, pulses_i, step_i, width_i, timestamp rise_value, fall_value, edge_value):
        if (self.edge_validation(rise_value, fall_value, edge_value)):
            if (delay_i = 0):
                self.pulse_override = True
                self.override_ends_ts = timestamp + width_i

            if (pulses_i = 1):
                self.next_acceptable_pulse_ts = timestamp + width_i
            else
                self.next_acceptable_pulse_ts = timestamp + overall_time


    def external_variable_internal_configuration(self):
        # Variable assignments from inputs
        delay = self.DELAY_L + (self.DELAY_H << 32)
        step = self.STEP_L + (self.STEP_H << 32)
        width = self.WIDTH_L + (self.WIDTH_H << 32)

        self.pulses_i = max(1, self.PULSES)

        if ((width > 5) or (width = 0)):
            self.width_i = width
        else
            self.width_i = 6    

       if ((delay > 5) or ((width != 0) and (delay = 0)) or ((width = 0) and (delay > 5))):
            self.width_i = width
        else
            self.width_i = 6

        if ((step > width) or (step = 0)):
            self.step_i = step
        else
            self.step_i = width_i + 1

        if ((step - width) > 1):
            self.gap_i = gap
        else
            self.gap_i = 1

        self.overall_time = (self.pulses_i * self.step_i) - gap_i


    def edge_detection(self, incoming_trigger):
        fall_trig = False
        rise_trig = False
        same_trig = False

        if   ((incoming_trigger = False) and (incoming_trigger != previous_trigger)):
            fall_trig = True
        elif ((incoming_trigger = True) and (incoming_trigger != previous_trigger)):
            rise_trig = True
        elif (incoming_trigger == previous_trigger):
            same_trig = True

        if (same_trig != True):
            if (self.timestamp < self.next_acceptable_pulse_ts):
                if (self.edge_validation(rise_trig, fall_trig, self.TRIG_EDGE)):
                    self.dropped_flag = True
            else
                self.delay_and_blocking_validation(self, self.delay_i, self.gap_i, self.overall_time, self.pulses_i, self.step_i, self.width_i, self.timestamp rise_trig, fall_trig, self.TRIG_EDGE)

        if (self.timestamp == override_ends_ts):
            self.pulse_override = False

        self.previous_trigger = incoming_trigger
        self.trig_fall = fall_trig
        self.trig_rise = rise_trig
        self.trig_same = same_trig


    def queue_filling(self):
        if (self.dropped_flag = True)
            self.missed_pulses += 1

        elif (self.trig_same == False):
            timestamp_to_queue = self.timestamp + self.delay_i - 2

            if (self.pulse_queue_full = True)
                self.missed_pulses += 1
                self.dropped_flag = False

            elif (self.width_i = 0):
                if(self.trig_rise = True):
                    self.pulse_queue.append((1, timestamp_to_queue))
                else:
                    self.pulse_queue.append((0, timestamp_to_queue))
            else:
                if(self.edge_validation(self.trig_rise, self.trig_fall, self.edge_value)):
                    self.pulse_queue.append((1, timestamp_to_queue))


    def process_queue(self):
        if (self.ENABLE = False):
            self.OUT = False
        else
            if (len(self.queue) == 1):
                self.queue_output, self.queue_timestamp = self.queue[0]

            if (self.width_i = 0):
                if (self.timestamp == self.queue_timestamp):
                    self.OUT = queue_output
                    self.queue_output, self.queue_timestamp = self.queue.pop()
            else
                if (pulses_i == 1):
                    if ((self.delay_i == 0) and (len(self.queue) != 0)):
                        self.queue_output, self.queue_timestamp = self.queue.pop()

                    elif ((self.timestamp == self.queue_output) and (self.queue_output != 0)):
                        self.OUT = 1
                        self.pulse_timestamp = self.timestamp + width_i

                    elif (self.timestamp == self.pulse_timestamp):
                        self.OUT = 0
                else
                    if (self.edges_remaining != 0):
                        if (self.timestamp == self.pulse_timestamp):
                            if (self.edges_remaining % 2):
                                self.edges_remaining -= 1
                                self.pulse_timestamp = self.timestamp + self.width_i
                                self.OUT = int(not bool(self.OUT))
                            else
                                self.edges_remaining -= 1
                                self.pulse_timestamp = self.timestamp + self.gap_i
                                self.OUT = int(not bool(self.OUT))

                            if (edges_remaining == 1):
                                self.queue_output, self.queue_timestamp = self.queue.pop()
                    else
                        if (self.queue_pulse_ts != 0):
                            if ((self.delay_i == 0) and ((self.timestamp - 6) == self.queue_timestamp)):
                                self.pulse_timestamp = self.timestamp + self.step_i - 5
                                self.edges_remaining = (self.pulses_i * 2) - 2

                            elif ((self.timestamp - 6) == self.queue_timestamp):
                                self.pulse_timestamp = self.timestamp + self.width_i - 5
                                self.edges_remaining = (self.pulses_i * 2) - 1


    def clear_queue(self, ts):
        """Clear the queue, but not any errors"""
        self.queue.clear()
        self.pulse_queue_full = False



    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""

        # CHANGES = ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, STEP_L, STEP_H, TRIG_EDGE, OUT, QUEUED, DROPPED
        super(PulseSimulation, self).on_changes(ts, changes)
        self.timestamp = ts

        # INCOMING CHANGES: ENABLE, TRIG, DELAY_L, DELAY_H, WIDTH_L, WIDTH_H, PULSES, STEP_L, STEP_H, TRIG_EDGE
        # OUTGOIG CHANGES:  OUT, QUEUED, DROPPED

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

        self.edge_detection()


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

        self.DROPPED = self.missed_pulses
        self.QUEUED = len(self.queue)