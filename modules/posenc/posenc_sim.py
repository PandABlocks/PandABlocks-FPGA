from common.python.simulations import BlockSimulation, properties_from_ini


NAMES, PROPERTIES = properties_from_ini(__file__, "posenc.block.ini")

DISABLED = 0
AT_POSITION = 1
SLEWING = 2

QUADRATURE = 0
STEP_DIRECTION = 1

# What is the next A,B position if going positive
QUAD_POSITIVE = {
    (0, 0): (1, 0),
    (1, 0): (1, 1),
    (1, 1): (0, 1),
    (0, 1): (0, 0)
}

# What is the next A,B position if going negative
QUAD_NEGATIVE = {v: k for k, v in QUAD_POSITIVE.items()}


class PosencSimulation(BlockSimulation):
    ENABLE, INP, PERIOD, PROTOCOL, A, B, STATE = PROPERTIES

    def __init__(self):
        # The last output value
        self.tracker = self.INP
        # The period clock start time
        self.clock_start = 0

    def next_ts(self, ts):
        # Do not allow PERIOD value of 1
        if self.PROTOCOL == STEP_DIRECTION:
            period = max(self.PERIOD, 2)
        else:
            period = self.PERIOD
        next_ts = (ts + 1) + period
        return next_ts

    def on_changes(self, ts, changes):
        super(PosencSimulation, self).on_changes(ts, changes)
        next_ts = None

        if changes.get(NAMES.PERIOD, None) is not None:
            # Period changes, change free running clock start
            self.clock_start = ts

        if changes.get(NAMES.ENABLE, None) is 1:
            # Reset on rising edge of enable
            self.tracker = self.INP
            self.A = 0
            self.B = 0
            self.STATE = AT_POSITION
        elif changes.get(NAMES.ENABLE, None) is 0:
            # Halt on falling edge of enable
            self.A = 0
            self.B = 0
            self.STATE = DISABLED
        elif self.ENABLE and self.PROTOCOL == QUADRATURE:
            # Enabled, so check based on state
            if self.STATE == AT_POSITION:
                if self.tracker != self.INP:
                    # Have moved, change state
                    self.STATE = SLEWING
                    next_ts = self.next_ts(ts)
            elif self.STATE == SLEWING:
                # Move one place in the right direction
                if self.INP > self.tracker:
                    self.A, self.B = QUAD_POSITIVE[(self.A, self.B)]
                    self.tracker += 1
                else:
                    self.A, self.B = QUAD_NEGATIVE[(self.A, self.B)]
                    self.tracker -= 1
                if self.tracker == self.INP:
                    next_ts = ts + 1
                else:
                    next_ts = self.next_ts(ts)
            if self.tracker == self.INP:
                # Have reached the right place
                self.STATE = AT_POSITION
                next_ts = ts + 1
        elif self.ENABLE and self.PROTOCOL == STEP_DIRECTION:
            if self.STATE == AT_POSITION:
                self.A = 0
                if self.B != 1:
                    # Direction is set one clock after initially entering state
                    self.B = 1
                    next_ts = ts + 1
                elif self.tracker != self.INP:
                    # Have moved, change state
                    self.STATE = SLEWING
                    self.B = self.INP < self.tracker
                    next_ts = self.next_ts(ts)
            elif self.STATE == SLEWING:
                if self.A:
                    self.A = 0
                    next_ts = self.next_ts(ts)
                else:
                    self.A = 1
                    next_ts = ts + 1
                    self.tracker += -1 if self.B else 1
                    if self.tracker == self.INP:
                        self.STATE = AT_POSITION
                        self.B = 1
        return next_ts
