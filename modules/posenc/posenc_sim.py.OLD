from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "posenc.block.ini")


class PosencSimulation(BlockSimulation):
    INP, QPERIOD, ENABLE, PROTOCOL, A, B, QSTATE = PROPERTIES

    def on_changes(self, ts, changes):
        super(PosencSimulation, self).on_changes(ts,changes)
        if NAMES.INP in changes:
            self.A = 0
            return ts + 1
        else:
            self.A = 1
