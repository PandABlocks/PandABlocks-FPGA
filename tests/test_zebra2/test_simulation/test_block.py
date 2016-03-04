#!/bin/env dls-python
import unittest
import sys
import os

# Module import
from pkg_resources import require
require("numpy")

sys.path.append(os.path.join(os.path.dirname(__file__),
                             "..", "..", "..", "python"))
config_dir = os.path.join(os.path.dirname(__file__),
                          "..", "..", "..", "config_d")
from zebra2.simulation.block import Block


class BlockTest(unittest.TestCase):

    def test_attrs(self):
        class Pulse(Block):
            pass
        Block.load_config(config_dir)
        p = Pulse()
        self.assertEqual(p.WIDTH_L, 0)
        self.assertEqual(p.config_block.WIDTH_L, "WIDTH_L")
        p.WIDTH_L = 32
        self.assertEqual(p._changes, dict(WIDTH_L=32))

if __name__=="__main__":
    unittest.main(verbosity=2)
