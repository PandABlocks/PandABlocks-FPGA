from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict

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

NAMES, PROPERTIES = properties_from_ini(__file__, "pcomp.block.ini")


class PcompSimulation(BlockSimulation):

    PRE_START, START, WIDTH, STEP, PULSES, RELATIVE, DIR, ENABLE, \
        INP, ACTIVE, OUT, HEALTH, PRODUCED, STATE = PROPERTIES

    def __init__(self):
        # The direction of the position compare
        self.dir_pos = 0
        # The position that we started at
        self.posn_latched = 0
        # The inp value at the start of the current pulse, and the next
        self.last_crossing = 0
        self.next_crossing = 0

    def pulse_start(self):
        if self.dir_pos or self.RELATIVE == 0:
            return self.START
        else:
            return -self.START

    def pulse_step(self):
        if self.dir_pos:
            return self.STEP
        else:
            return -self.STEP

    def pulse_width(self):
        if self.dir_pos:
            return self.WIDTH
        else:
            return -self.WIDTH

    def posn(self):
        if self.RELATIVE:
            return self.INP - self.posn_latched
        else:
            return self.INP

    def exceeded_prestart(self):
        if self.dir_pos:
            return self.posn() < self.pulse_start() - self.PRE_START
        else:
            return self.posn() > self.pulse_start() + self.PRE_START

    def reached_next_crossing(self):
        if self.next_crossing >= self.last_crossing:
            return self.posn() >= self.next_crossing
        else:
            return self.posn() <= self.next_crossing

    def jumped_more_than_step(self):
        too_far = self.last_crossing + self.pulse_step()
        return (self.last_crossing <= self.next_crossing
                <= too_far <= self.posn()) or \
               (self.last_crossing >= self.next_crossing
                >= too_far >= self.posn())

    def guess_dir_thresh(self):
        return self.START + self.PRE_START

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(PcompSimulation, self).on_changes(ts, changes)

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Handle enable transitions
        state = self.STATE

        if changes.get(NAMES.ENABLE, None) is 0:
            # When disabled, set outputs
            self.ACTIVE = 0
            self.OUT = 0
            state = WAIT_ENABLE
        else:
            if self.STATE == WAIT_ENABLE:
                if changes.get(NAMES.ENABLE, None) is 1:
                    # When enabled, reset outputs and readbacks
                    self.ACTIVE = 1
                    self.HEALTH = OK
                    self.PRODUCED = 0
                    # Latch the position when we started
                    self.posn_latched = self.INP
                    # Direction is specified or guessed
                    if self.DIR == EITHER:
                        state = WAIT_DIR
                    else:
                        if self.DIR == POSITIVE:
                            self.dir_pos = 1
                        else:
                            self.dir_pos = 0
                        state = WAIT_PRE_START
            if self.STATE == WAIT_DIR:
                if self.RELATIVE:
                    # If we are relative then only advance when thresh away from
                    # the initial position
                    if self.guess_dir_thresh() > 0:
                        if abs(self.posn()) >= self.guess_dir_thresh():
                            if self.PRE_START > 0:
                                self.dir_pos = self.posn() < 0
                                state = WAIT_PRE_START
                            else:
                                self.OUT = 1
                                self.PRODUCED = 1
                                if self.posn() > 0:
                                    self.dir_pos = 1
                                    self.last_crossing = self.START
                                    self.next_crossing = self.START + self.WIDTH
                                else:
                                    self.dir_pos = 0
                                    self.last_crossing = -self.START
                                    self.next_crossing = -self.START-self.WIDTH
                                state = WAIT_FALLING
                    else:
                        self.HEALTH = ERR_GUESS
                        self.ACTIVE = 0
                        state = WAIT_ENABLE
                elif self.START != self.posn():
                    self.dir_pos = self.posn() < self.START
                    state = WAIT_PRE_START
            elif self.STATE == WAIT_PRE_START:
                # Check we have crossed thresh IN OPPOSITE DIRECTION
                if self.exceeded_prestart():
                    if self.dir_pos:
                        self.last_crossing = self.pulse_start() - 1
                    else:
                        self.last_crossing = self.pulse_start() + 1
                    self.next_crossing = self.pulse_start()
                    state = WAIT_RISING
            elif self.STATE == WAIT_RISING:
                if self.reached_next_crossing():
                    if self.jumped_more_than_step():
                        self.ACTIVE = 0
                        self.HEALTH = ERR_PJUMP
                        state = WAIT_ENABLE
                    else:
                        self.OUT = 1
                        self.PRODUCED += 1
                        self.last_crossing, self.next_crossing = (
                            self.next_crossing,
                            self.next_crossing + self.pulse_width())
                        state = WAIT_FALLING
            elif self.STATE == WAIT_FALLING:
                # Check when we have passed WIDTH
                if self.reached_next_crossing():
                    self.OUT = 0
                    if self.PRODUCED == self.PULSES:
                        self.ACTIVE = 0
                        state = WAIT_ENABLE
                    elif self.jumped_more_than_step():
                        self.ACTIVE = 0
                        self.HEALTH = ERR_PJUMP
                        state = WAIT_ENABLE
                    else:
                        self.last_crossing, self.next_crossing = (
                            self.next_crossing,
                            self.last_crossing + self.pulse_step())
                        state = WAIT_RISING

        if state != self.STATE:
            self.STATE = state
            # We changed state, might need another transition next clock tick
            return ts + 1
