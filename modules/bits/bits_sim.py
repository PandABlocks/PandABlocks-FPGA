from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "bits.block.ini")


class BitsSimulation(BlockSimulation):
    A, B, C, D, OUTA, OUTB, OUTC, OUTD = PROPERTIES

    def on_changes(self, ts, changes):
        """Handle field changes at a particular timestamp

        Args:
            ts (int): The timestamp the changes occurred at
            changes (Dict[str, int]): Fields that changed with their value

        Returns:
             If the Block needs to be called back at a particular ts then return
             that int, otherwise return None and it will be called when a field
             next changes
        """
        # Set attributes
        super(BitsSimulation, self).on_changes(ts, changes)

        for name, value in changes.items():
            if name in 'ABCD':
                setattr(self, 'OUT'+name, value)
