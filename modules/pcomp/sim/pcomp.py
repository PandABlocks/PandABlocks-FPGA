from common.python.pandablocks.block import Block

import numpy as np

# state machine states
WAIT_ENABLE = 0
WAIT_DIR = 1
WAIT_PRE_START = 2
WAIT_RISING = 3
WAIT_FALLING = 4

# for directions
POSITIVE = 0
NEGATIVE = 1
EITHER = 2

# for errors
OK = 0
ERR_PJUMP = 1
ERR_GUESS = 2


class Pcomp(Block):

    def __init__(self):
        # The direction of the position compare
        self.negative = 0
        # The position that we started at
        self.initial = 0
        # The inp value at the start of the current pulse, and the next
        self.current_crossing = 0
        self.next_crossing = 0

    def pulse_start(self):
        if self.RELATIVE:
            if self.negative:
                return self.initial - self.START
            else:
                return self.initial + self.START
        else:
            return self.START

    def pulse_step(self):
        if self.negative:
            return -self.STEP
        else:
            return self.STEP

    def pulse_width(self):
        if self.negative:
            return -self.WIDTH
        else:
            return self.WIDTH

    def exceeded_pre_start(self):
        if self.negative:
            return self.INP > self.pulse_start() + self.PRE_START
        else:
            return self.INP < self.pulse_start() - self.PRE_START

    def reached_current_crossing(self):
        if self.negative:
            return self.INP <= self.current_crossing
        else:
            return self.INP >= self.current_crossing

    def reached_next_crossing(self):
        if self.negative:
            return self.INP <= self.next_crossing
        else:
            return self.INP >= self.next_crossing

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Handle enable transitions
        state = self.STATE

        if b.ENABLE in changes:
            if self.ENABLE:
                # When enabled, reset outputs and readbacks
                self.ACTIVE = 1
                self.HEALTH = OK
                self.PRODUCED = 0
                # Latch the position when we started
                self.initial = self.INP
                # Direction is specified or guessed
                if self.DIR == EITHER:
                    state = WAIT_DIR
                else:
                    self.negative = self.DIR
                    state = WAIT_PRE_START
            else:
                # When disabled, set outputs
                self.ACTIVE = 0
                self.OUT = 0
                state = WAIT_ENABLE
        elif self.ACTIVE:
            if self.STATE == WAIT_DIR:
                if self.RELATIVE:
                    # If we are relative then only advance when thresh away from
                    # the initial position
                    if self.START + self.PRE_START > 0:
                        if abs(self.INP - self.initial) >= \
                                        self.START + self.PRE_START:
                            if self.PRE_START > 0:
                                self.negative = self.INP > self.initial
                                state = WAIT_PRE_START
                            else:
                                self.OUT = 1
                                self.PRODUCED = 1
                                self.current_crossing = \
                                    self.pulse_start() + self.pulse_width()
                                self.next_crossing = \
                                    self.pulse_start() + self.pulse_step()
                                self.negative = self.INP < self.initial
                                state = WAIT_FALLING
                    else:
                        self.HEALTH = ERR_GUESS
                        self.ACTIVE = 0
                        state = WAIT_ENABLE
                elif self.START != self.INP:
                    self.negative = self.INP > self.START
                    state = WAIT_PRE_START
            elif self.STATE == WAIT_PRE_START:
                # Check we have crossed thresh IN OPPOSITE DIRECTION
                if self.exceeded_pre_start():
                    self.current_crossing = self.pulse_start()
                    self.next_crossing = self.pulse_start() + self.pulse_width()
                    state = WAIT_RISING
            elif self.STATE == WAIT_RISING:
                # Check when we have passed current_crossing
                if self.reached_current_crossing():
                    if self.reached_next_crossing():
                        self.ACTIVE = 0
                        self.HEALTH = ERR_PJUMP
                        state = WAIT_ENABLE
                    else:
                        self.OUT = 1
                        self.PRODUCED += 1
                        self.current_crossing, self.next_crossing = (
                            self.next_crossing,
                            self.current_crossing + self.pulse_step())
                        state = WAIT_FALLING
            elif self.STATE == WAIT_FALLING:
                # Check when we have passed WIDTH
                if self.reached_current_crossing():
                    self.OUT = 0
                    if self.reached_next_crossing():
                        self.ACTIVE = 0
                        self.HEALTH = ERR_PJUMP
                        state = WAIT_ENABLE
                    elif self.PRODUCED == self.PULSES:
                        self.ACTIVE = 0
                        state = WAIT_ENABLE
                    else:
                        self.current_crossing, self.next_crossing = (
                            self.next_crossing,
                            self.current_crossing + self.pulse_step())
                        state = WAIT_RISING

        if state != self.STATE:
            self.STATE = state
            # We changed state, might need another transition next clock tick
            return ts + 1

