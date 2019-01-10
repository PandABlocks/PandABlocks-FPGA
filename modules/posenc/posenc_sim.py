from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "posenc.block.ini")


class PosencSimulation(BlockSimulation):
    ENABLE, INP, PERIOD, PROTOCOL, A, B, STATE = PROPERTIES

    def __init__(self):
        self.dir = 0
        self.tracker = self.INP
        self.state = 0
        self.equal = 0
        self.newstate = 0
        self.nexttime = 0
        self.setb = 0
        self.period = 0

    def on_changes(self, ts, changes):
        super(PosencSimulation, self).on_changes(ts, changes)
        # set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Do not allow PERIOD value of 1
        if self.PERIOD == 1:
            self.period = 2
        else:
            self.period = self.PERIOD

        if changes.get(NAMES.ENABLE, None) is 0:
            self.A = 0
            self.STATE = 0
            self.tracker = self.INP
            self.B = 0

        else:
            if self.ENABLE == 1:
                # If the input changes the system requires a clock tick to
                # process so if the next clock is the current time, the module
                # will next function on the next clock
                if changes.get(NAMES.INP):
                    if self.nexttime < ts + 1:
                        self.nexttime = self.nexttime + self.period

                # Set the direction
                self.equal = 0
                if self.INP > self.tracker:
                    self.dir = 0
                elif self.INP < self.tracker:
                    self.dir = 1
                else:
                    self.equal = 1
                    self.dir = 1

                # Change the internal state and increment tracker
                if self.dir == 0 and ts == self.nexttime and self.equal == 0:
                    if self.state < 3:
                        self.newstate += 1
                    else:
                        self.newstate = 0
                    self.tracker += 1
                elif ts >= self.nexttime and self.equal == 0:
                    if self.state > 0:
                        self.newstate -= 1
                    else:
                        self.newstate = 3
                    self.tracker -= 1
                # Set STATE output
                if self.equal == 1:
                    self.STATE = 1
                else:
                    self.STATE = 2

                # Set A and B output for Quadrature mode
                if self.PROTOCOL == 0 and ts >= self.nexttime:
                    self.state = self.newstate
                    if self.state == 0:
                        self.A = 0
                        self.B = 0

                    elif self.state == 1:
                        self.A = 1
                        self.B = 0

                    elif self.state == 2:
                        self.A = 1
                        self.B = 1

                    else:
                        self.A = 0
                        self.B = 1
                # Set A and B output for Step/Direction Mode
                elif self.PROTOCOL == 1:
                    # Set B on the next clock cycle
                    if self.setb == 1:
                        self.setb = 0
                    else:
                        self.B = self.dir

                    if self.equal == 0 and ts == self.nexttime:
                        self.state = self.newstate
                        self.A = 1
                    else:
                        self.A = 0

            else:
                    self.tracker = self.INP
                    # If the input is set at the start, the initial direction
                    # takes an extra clock to set. This affects the B output
                    # for PROTOCOL=1
                    if self.PROTOCOL == 1 and self.INP > 0:
                        self.setb = 1
                    else:
                        self.setb = 0
        # The module uses a prescaler which generates a pulse each time it
        # counts to the inputted PERIOD value
        if ts == self.nexttime or changes.get(NAMES.PERIOD):
            self.nexttime = ts + self.period
        return ts + 1
