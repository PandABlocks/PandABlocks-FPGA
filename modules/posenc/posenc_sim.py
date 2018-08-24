from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "posenc.block.ini")


class PosencSimulation(BlockSimulation):
    INP, PERIOD, ENABLE, PROTOCOL, A, B, STATE = PROPERTIES

    def __init__(self):
        self.dir = 0
        self.tracker = self.INP
        self.start = 0
        self.state = 0
        self.laststep = 0
        self.equal = 0
        self.newstate = 0
        self.laststate = 0
        self.halfpulse = 0
        self.pulse = 0
        self.nextb = 0

    def on_changes(self, ts, changes):
        super(PosencSimulation, self).on_changes(ts, changes)
        # set attributes
        for name, value in changes.items():
            setattr(self, name, value)
        if changes.get(NAMES.ENABLE, None) is 0:
            self.A = 0
            self.B = 0
            self.STATE = 0
            self.tracker = self.INP

        else:
            if self.ENABLE == 1:
                # Set the direction
                self.equal = 0
                self.STATE = self.extstate
                if self.INP > self.tracker:
                    self.dir = 0
                elif self.INP < self.tracker:
                    self.dir = 1
                else:
                    self.equal = 1
                    self.dir = 1

                # Change the internal state and increment tracker
                if self.dir == 0 and (ts >= self.laststep + self.PERIOD) \
                        and self.equal == 0:
                    if self.state < 3:
                        self.newstate += 1
                    else:
                        self.newstate = 0
                    self.tracker += 1
                elif ts >= self.laststep + self.PERIOD and self.equal == 0:
                    if self.state > 0:
                        self.newstate -= 1
                    else:
                        self.newstate = 3
                    self.tracker -= 1

                # Set STATE output
                if self.equal == 1:
                    self.extstate = 1
                else:
                    self.STATE = 2
                    self.extstate = 2

                # Set A and B output
                if self.PROTOCOL == 0 and (ts >= self.laststep + self.PERIOD):
                    self.laststep = ts
                    if self.state == 0:
                        self.A = 0
                        self.B = 0
                        self.state = self.newstate
                        return ts + self.PERIOD
                    elif self.state == 1:
                        self.A = 1
                        self.B = 0
                        self.state = self.newstate
                        return ts + self.PERIOD
                    elif self.state == 2:
                        self.A = 1
                        self.B = 1
                        self.state = self.newstate
                        return ts + self.PERIOD
                    else:
                        self.A = 0
                        self.B = 1
                        self.state = self.newstate
                        return ts + self.PERIOD

            else:
                    self.tracker = self.INP
                    self.extstate = 1

            return ts + 1






#        if NAMES.INP in changes:
  #          self.A = 0
 #           return ts + 1
 #       else:
 #           self.A = 1