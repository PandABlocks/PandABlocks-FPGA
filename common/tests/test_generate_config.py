import unittest
from common.python.generate_config import BlockConfig


class TestBlockConfig(unittest.TestCase):
    maxDiff=None

    def setUp(self):
        self.lut = BlockConfig("LUT", "lut", "lut_block.ini", 9, 8)

    def test_lut_description(self):
        expected = """LUT\tLookup table
\tFUNC\tInput func
\tA\tSource of the value of A for calculation
\tB\tSource of the value of B for calculation
\tC\tSource of the value of C for calculation
\tD\tSource of the value of D for calculation
\tE\tSource of the value of E for calculation
\tINPA\tInput A
\tINPB\tInput B
\tINPC\tInput C
\tINPD\tInput D
\tINPE\tInput E
\tOUT\tLookup table output"""
        self.assertMultiLineEqual(
            "\n".join(self.lut.description_lines()), expected)

    def test_lut_config(self):
        expected = """LUT[8]
\tFUNC\tparam\tlut
\tA\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tB\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tC\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tD\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tE\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tINPA\tbit_mux
\tINPB\tbit_mux
\tINPC\tbit_mux
\tINPD\tbit_mux
\tINPE\tbit_mux
\tOUT\tbit_out"""
        self.assertMultiLineEqual(
            "\n".join(self.lut.config_lines()), expected)

    def test_lut_register(self):
        expected = """LUT\t9
\tFUNC\t0
\tA\t1
\tB\t2
\tC\t3
\tD\t4
\tE\t5
\tINPA\t6 7
\tINPB\t8 9
\tINPC\t10 11
\tINPD\t12 13
\tINPE\t14 15
\tOUT\t32 33 34 35 36 37 38 39"""
        self.assertMultiLineEqual(
            "\n".join(self.lut.register_lines()), expected)

if __name__ == '__main__':
    unittest.main()