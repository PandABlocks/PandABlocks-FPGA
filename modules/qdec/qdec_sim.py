from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "qdec.block.ini")


class QdecSimulation(BlockSimulation):
    RST_ON_Z, SETP, A, B, Z, OUT = PROPERTIES

    def __init__(self):
        self.state = 0
        self.newstate = 0
        self.dir = 0
        self.count = 0
        self.update = 0
        self.lastts = 0

    def on_changes(self, ts, changes):
        super(QdecSimulation, self).on_changes(ts, changes)

        if changes.get(NAMES.SETP, None):
            self.count = self.SETP
            self.OUT = self.count
            self.state = self.newstate
            self.update = 0
            return
        else:
            if self.RST_ON_Z == 1 and self.Z == 1:
                self.count = 0
                self.OUT = 0

            elif self.update == 1:
                if self.state == 3 and self.newstate == 0:
                    self.dir = 0
                elif self.state == 0 and self.newstate == 3:
                    self.dir = 1
                elif self.newstate > self.state:
                    self.dir = 0
                elif self.newstate < self.state:
                    self.dir = 1
                self.state = self.newstate
                if ts >= self.lastts + 2:
                    if self.dir == 1:
                        self.count -= 1
                    else:
                        self.count += 1
                    self.OUT = self.count
                    self.update = 0
                    self.lastts = 0

            if self.A == 0 and self.B == 0:
                self.newstate = 0
            elif self.A == 1 and self.B == 0:
                self.newstate = 1
            elif self.A == 1 and self.B == 1:
                self.newstate = 2
            elif self.A == 0 and self.B == 1:
                self.newstate = 3
            if self.newstate != self.state:
                self.update = 1
                if self.lastts == 0:
                    self.lastts = ts
            return ts + 2
