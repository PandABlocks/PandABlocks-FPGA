#!/bin/env dls-python
from pkg_resources import require
require("mock")

import unittest
import sys
import os
from mock import MagicMock

from collections import OrderedDict

# Module import
sys.path.append(os.path.join(os.path.dirname(__file__),
                             "..", "..", "..", "python"))
from zebra2.configparser.configblock import ConfigBlock


class BlockTest(unittest.TestCase):

    def test_multi(self):
        c = "SEQ[4]"
        r = "SEQ    5"
        d = "SEQ    A sequencer block"
        b = ConfigBlock(r, c, d)
        self.assertEqual(b.name, "SEQ")
        self.assertEqual(b.num, 4)
        self.assertEqual(b.base, 5)
        self.assertEqual(b.desc, "A sequencer block")
        self.assertEqual(b.fields, OrderedDict())

    def test_single(self):
        c = "PCAP"
        r = "PCAP    2"
        d = "PCAP    Position capture"
        b = ConfigBlock(r, c, d)
        self.assertEqual(b.name, "PCAP")
        self.assertEqual(b.num, 1)
        self.assertEqual(b.base, 2)
        self.assertEqual(b.desc, "Position capture")
        self.assertEqual(b.fields, OrderedDict())

    def test_add_field(self):
        f = MagicMock()
        f.name = "FIELD"
        b = ConfigBlock("name 1", "name", "name desc")
        b.add_field(f)
        self.assertEqual(b.fields.keys(), ["FIELD"])
        self.assertEqual(b.FIELD, "FIELD")
        self.assertEqual(b.fields.values(), [f])
        self.assertRaises(AssertionError, b.add_field, f)

    def test_no_config(self):
        r = "BLOCK 4"
        b = ConfigBlock(r)
        self.assertEqual(b.name, "BLOCK")
        self.assertEqual(b.num, 1)
        self.assertEqual(b.base, 4)
        self.assertEqual(b.desc, None)
        self.assertEqual(b.fields, OrderedDict())

if __name__=="__main__":
    unittest.main(verbosity=2)
