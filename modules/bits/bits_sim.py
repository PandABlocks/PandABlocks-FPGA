from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict, Optional


NAMES, PROPERTIES = properties_from_ini(__file__, "bits.block.ini")


class BitsSimulation(BlockSimulation):
    A, B, C, D, OUTA, OUTB, OUTC, OUTD = PROPERTIES

    def on_changes(self, ts, changes):
        # type: (int, Dict[str, int]) -> Optional[int]
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # Set attributes
        super(BitsSimulation, self).on_changes(ts, changes)

        for name, value in changes.items():
            if name in 'ABCD':
                setattr(self, 'OUT'+name, value)

        return None
