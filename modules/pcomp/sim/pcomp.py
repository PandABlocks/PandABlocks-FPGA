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
        # The sign multiplier for direction, None for not guessed yet
        self.mult = None
        # The position that we started at
        self.initial = 0
        # The inp value at the start of the current pulse
        self.current_pulse = None

    def do_enable(self):
        # When enabled, reset outputs and readbacks
        self.ACTIVE = 1
        self.OUT = 0
        self.HEALTH = OK
        self.PRODUCED = 0
        # Latch the position when we started
        self.initial = self.INP
        self.current_pulse = None
        # Direction is specified or guessed
        if self.DIR == POSITIVE:
            self.mult = 1
        elif self.DIR == NEGATIVE:
            self.mult = -1
        elif self.DIR == EITHER:
            self.mult = None
            return WAIT_DIR
        # Return the initial state
        return WAIT_PRE_START

    def do_disable(self, health=OK):
        # When disabled, set outputs but leave readbacks
        self.ACTIVE = 0
        self.OUT = 0
        self.HEALTH = health
        return WAIT_ENABLE

    def reached_thresh(self, inp, threshold):
        return self.mult * (inp - threshold) >= 0

    def do_produce_rising(self, current_pulse):
        falling = current_pulse + self.mult * self.WIDTH
        if self.reached_thresh(self.INP, falling):
            return self.do_disable(ERR_PJUMP)
        else:
            self.OUT = 1
            self.PRODUCED += 1
            self.current_pulse = current_pulse
            return WAIT_FALLING

    def do_produce_falling(self):
        self.OUT = 0
        if self.PRODUCED == self.PULSES:
            self.ACTIVE = 0
            return WAIT_ENABLE
        else:
            rising = self.current_pulse + self.mult * self.STEP
            if self.reached_thresh(self.INP, rising):
                return self.do_disable(ERR_PJUMP)
            else:
                return WAIT_RISING

    def pre_start_thresh(self):
        if self.RELATIVE:
            thresh = self.initial + self.mult * (self.START - self.PRE_START)
        else:
            thresh = self.START - self.mult * self.PRE_START
        return thresh

    def do_check_dir(self):
        if self.RELATIVE:
            # If we are relative then only advance when thresh away from
            # the initial position
            if self.PRE_START > 0:
                if abs(self.INP - self.initial) > self.PRE_START:
                    # The sign is the other way from where we are going
                    self.mult = np.sign(self.initial - self.INP)
                    return WAIT_RISING                    
            elif self.START > 0:
                if abs(self.INP - self.initial) >= self.START:
                    self.mult = np.sign(self.INP - self.initial)
                    return self.do_rising_check()
            else:
                return self.do_disable(ERR_GUESS)
        else:
            sign = np.sign(self.START - self.INP)
            if sign != 0:
                self.mult = sign
                return WAIT_PRE_START
        return WAIT_DIR

    def do_pre_start_check(self):
        # Check we have crossed thresh IN OPPOSITE DIRECTION
        if self.mult * (self.INP - self.pre_start_thresh()) < 0:
            return WAIT_RISING
        else:
            return WAIT_PRE_START

    def rising_thresh(self):
        if self.current_pulse is None:
            if self.RELATIVE:
                thresh = self.initial + self.mult * self.START
            else:
                thresh = self.START
        else:
            thresh = self.current_pulse + self.mult * self.STEP
        return thresh

    def do_rising_check(self):
        thresh = self.rising_thresh()
        if self.reached_thresh(self.INP, thresh):
            return self.do_produce_rising(thresh)
        else:
            return WAIT_RISING

    def falling_thresh(self):
        return self.current_pulse + self.mult * self.WIDTH

    def do_falling_check(self):
        thresh = self.falling_thresh()
        if self.reached_thresh(self.INP, thresh):
            return self.do_produce_falling()
        else:
            return WAIT_FALLING

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Handle enable transitions
        state = None

        if b.ENABLE in changes:
            if self.ENABLE:
                # If we get enabled then start listening for points
                state = self.do_enable()
            else:
                state = self.do_disable()
        elif self.ACTIVE:
            if self.STATE == WAIT_DIR:
                # Check when we have passed START - PRE_START
                state = self.do_check_dir()
                
            elif self.STATE == WAIT_PRE_START:
                # Check when we have passed START - PRE_START
                state = self.do_pre_start_check()
            elif self.STATE == WAIT_RISING:
                # Check when we have passed START
                state = self.do_rising_check()
            elif self.STATE == WAIT_FALLING:
                # Check when we have passed WIDTH
                state = self.do_falling_check()
        
        if state is not None:
            self.STATE = state
            # We changed state, might need another transition next clock tick
            return ts + 1

