#!/bin/env dls-python
import unittest
import sys
import os

# Module import
sys.path.append(os.path.join(os.path.dirname(__file__),
                             "..", "..", "..", "python"))
from zebra2.configparser.configparser import ConfigParser

class DummyParser(ConfigParser):
    def parse(self):
        pass

class ParserTest(unittest.TestCase):
    def test_parse_block(self):
        p = DummyParser("anything")
        block = """# something

BLOCK[4]
    # comment field
    FIELD   4
    ANOTHER 4
        meta 1
        meta 2
    # and more
    THIS 0

BLOCK2[3]
"""
        lines = block.splitlines(True)
        lines.reverse()
        n, l, fields = p._parse_block(lines)
        self.assertEqual(l, "BLOCK[4]")
        self.assertEqual(n, "BLOCK")
        self.assertEqual(lines, ["BLOCK2[3]\n"])

    def test_full_parser(self):
        config_dir = os.path.join(os.path.dirname(__file__),
                                  "..", "..", "..", "config_d")
        p = ConfigParser(config_dir)
        ttlin = p.blocks["TTLIN"]
        self.assertEqual(ttlin.fields.keys(), ["VAL", "TERM"])
        val = ttlin.fields["VAL"]
        self.assertEqual(val.cls, "bit_out")
        self.assertEqual(val.name, "VAL")
        self.assertEqual(val.reg[0], "2")
        self.assertEqual(val.desc, "TTL input value")

if __name__=="__main__":
    unittest.main(verbosity=2)
