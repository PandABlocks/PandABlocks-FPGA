import unittest
from pkg_resources import require
require("numpy")

from common.python.simulations import BlockSimulation, properties_from_ini


NAMES, PROPERTIES = properties_from_ini(__file__, "test.block.ini")


class MyTest(BlockSimulation):
    FUNC, A, INPA, OUT = PROPERTIES


class TestBlockSimulation(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.o = MyTest()

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
                BAD, A, INPA, OUT = PROPERTIES

        assert str(cm.exception) == \
               "Property BAD mismatch with FieldConfig name FUNC"


if __name__ == '__main__':
    unittest.main()