#!/bin/env dls-python
import unittest
import sys
import os

# Module import
sys.path.append(os.path.join(os.path.dirname(__file__),
                             "..", "..", "..", "python"))
from zebra2.configparser.configfield import ConfigField


class FieldTest(unittest.TestCase):

    def test_param(self):
        r = "    VAL    3\n".splitlines()
        c = "    VAL    param    bit_mux\n".splitlines()
        d = "    VAL    What value to output\n".splitlines()
        f = ConfigField("VAL", r, c, d)
        self.assertEqual(f.name, "VAL")
        self.assertEqual(f.cls, "param")
        self.assertEqual(f.cls_args, ["bit_mux"])
        self.assertEqual(f.cls_extra, [])
        self.assertEqual(f.reg, ["3"])
        self.assertEqual(f.desc, "What value to output")

    def test_enum(self):
        r = "    SET_EDGE    2\n".splitlines()
        c = """    SET_EDGE    param    enum 2
        0   Rising
        1   Falling\n""".splitlines()
        d = "    SET_EDGE    Edge for set\n".splitlines()
        f = ConfigField("SET_EDGE", r, c, d)
        self.assertEqual(f.name, "SET_EDGE")
        self.assertEqual(f.cls, "param")
        self.assertEqual(f.cls_args, ["enum", "2"])
        self.assertEqual(f.cls_extra, ["0   Rising", "1   Falling"])
        self.assertEqual(f.reg, ["2"])
        self.assertEqual(f.desc, "Edge for set")

    def test_table(self):
        r = "    TABLE    short   512    13 14 1\n".splitlines()
        c = """    TABLE    table
        31:0  NREPEATS
        35:32 INPUT_MASK\n""".splitlines()
        d = "    TABLE    Sequencer table\n".splitlines()
        f = ConfigField("TABLE", r, c, d)
        self.assertEqual(f.name, "TABLE")
        self.assertEqual(f.cls, "table")
        self.assertEqual(f.cls_args, [])
        self.assertEqual(f.cls_extra, ["31:0  NREPEATS", "35:32 INPUT_MASK"])
        self.assertEqual(f.reg, ["short", "512", "13", "14", "1"])
        self.assertEqual(f.desc, "Sequencer table")

    def test_wrong_reg_name(self):
        r = "bar 2\n".splitlines()
        c = "foo 1\n".splitlines()
        d = "foo desc\n".splitlines()
        self.assertRaises(AssertionError, ConfigField, "bar", r, c, d)

    def test_no_config(self):
        r = "    START_REG 4\n".splitlines()
        f = ConfigField("START_REG", r)
        self.assertEqual(f.name, "START_REG")
        self.assertEqual(f.cls, None)
        self.assertEqual(f.cls_args, None)
        self.assertEqual(f.cls_extra, None)
        self.assertEqual(f.reg, ["4"])
        self.assertEqual(f.desc, None)

    def test_no_reg(self):
        c = "    ARM  software\n".splitlines()
        f = ConfigField("ARM", config_lines=c)
        self.assertEqual(f.name, "ARM")
        self.assertEqual(f.cls, "software")
        self.assertEqual(f.cls_args, [])
        self.assertEqual(f.cls_extra, [])
        self.assertEqual(f.reg, None)
        self.assertEqual(f.desc, None)

if __name__ == '__main__':
    unittest.main(verbosity=2)
