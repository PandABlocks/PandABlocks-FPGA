from common.python.simulations import BlockSimulation, properties_from_ini, \
	TYPE_CHECKING

if TYPE_CHECKING:
	from typing import Dict


NAMES, PROPERTIES = properties_from_ini(__file__, "qdec.block.ini")


class QdecSimulation(BlockSimulation):
	RST_ON_Z, SETP, A, B, Z, OUT = PROPERTIES

	def on_changes(self, ts, changes):
		super(QdecSimulation, self).on_changes(ts, changes)
		if NAMES.A in changes:
			self.OUT = 1
			return ts + 1
		else:
			self.OUT = 0
