import unittest
from pkg_resources import require
require("numpy")

from common.python.simulations import BlockSimulation, properties_from_ini


class MySim(BlockSimulation):
    FUNC, A, INPA, OUT = properties_from_ini(__file__, "block_simulation.ini")


class TestBlockSimulation(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.o = MySim()

    def test_setter(self):
        assert self.o.changes is None
        self.o.OUT = 45
        assert self.o.OUT == 45
        assert self.o.changes == dict(OUT=45)
        self.o.A = 46
        assert self.o.changes == dict(OUT=45, A=46)
        self.o.OUT = 48
        assert self.o.OUT == 48
        assert self.o.changes == dict(OUT=48, A=46)

    def test_bad_fields(self):
        with self.assertRaises(AssertionError) as cm:
            class MyBad(BlockSimulation):
                BAD, A, INPA, OUT = properties_from_ini(
                    __file__, "block_simulation.ini")
        assert str(cm.exception) == \
               "Property BAD mismatch with FieldConfig name FUNC"


if __name__ == '__main__':
    unittest.main()