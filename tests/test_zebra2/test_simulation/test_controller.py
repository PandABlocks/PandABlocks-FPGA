#!/bin/env dls-python
import unittest
import sys
import os
import time

from pkg_resources import require
require("numpy")

# Module import
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..",
                             "python"))
from zebra2.simulation.controller import Controller, Block, CLOCK_TICK


class ControllerTest(unittest.TestCase):

    def setUp(self):
        config_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..",
                                  "config_d")
        self.c = Controller(config_dir)

    def test_init(self):
        for i, val in enumerate(Block.bit_bus):
            if i == Block.parser.bit_bus["BITS.ONE"]:
                self.assertEqual(val, 1, "Bit bus index %d != 1" % i)
            else:
                self.assertEqual(val, 0, "Bit bus index %d != 0" % i)
        for i, val in enumerate(Block.pos_bus):
            self.assertEqual(val, 0)

    def test_clocks_set(self):
        clocks_config = Block.parser.blocks["CLOCKS"]
        clocks_period_reg = int(clocks_config.fields["A_PERIOD"].reg[0])
        clocks_a_idx = Block.parser.bit_bus["CLOCKS.A"]
        clocks, attr = self.c.lookup[(clocks_config.base, 0, clocks_period_reg)]
        self.assertEqual(clocks.A_PERIOD, 0)
        self.assertEqual(self.c.wakeups, [])
        self.assertEqual(clocks.A, 0)
        # set 1s period
        s = int(1.0 / CLOCK_TICK + 0.5)
        self.c.do_write_register(clocks_config.base, 0, clocks_period_reg, s)
        # number of clockticks to reg set
        reg_ticks = (time.time() - self.c.start_time) / CLOCK_TICK
        self.assertEqual(clocks.A_PERIOD, s)
        self.assertEqual(len(self.c.wakeups), 1)
        # check wakeup scheduled for 0.5s from now
        self.assertAlmostEqual(
            self.c.wakeups[0][0], reg_ticks + s / 2, delta=10000)
        self.assertEqual(self.c.wakeups[0][1], clocks)
        self.assertEqual(self.c.wakeups[0][2], {})
        self.assertEqual(clocks.A, 0)
        self.assertEqual(Block.bit_bus[clocks_a_idx], 0)
        # handle another event
        timeout = self.c.calc_timeout()
        self.assertAlmostEqual(timeout, 0.5, delta=0.001)
        time.sleep(0.5)
        self.c.do_tick()
        self.assertEqual(clocks.A_PERIOD, s)
        self.assertEqual(len(self.c.wakeups), 1)
        self.assertAlmostEqual(
            self.c.wakeups[0][0], reg_ticks + s, delta=10000)
        self.assertEqual(self.c.wakeups[0][1], clocks)
        self.assertEqual(clocks.A, 1)
        self.assertEqual(Block.bit_bus[clocks_a_idx], 1)

    def test_changing_inp(self):
        div_config = Block.parser.blocks["DIV"]
        div_inp_reg = int(div_config.fields["INP"].reg[0])
        div, inp = self.c.lookup[(div_config.base, 0, div_inp_reg)]
        bits_config = Block.parser.blocks["BITS"]
        bits_a_set_reg = int(bits_config.fields["A_SET"].reg[0])
        bits, a_set = self.c.lookup[(bits_config.base, 0, bits_a_set_reg)]
        bits_a_idx = Block.parser.bit_bus["BITS.A"]
        self.assertEqual(inp, "INP")
        self.assertEqual(a_set, "A_SET")
        # check disconnected
        self.assertEqual(div.INP, 0)
        # connect to BITS.A
        self.c.do_write_register(div_config.base, 0, div_inp_reg, bits_a_idx)
        self.assertEqual(div.INP, 0)
        self.assertEqual(self.c.listeners[(bits, "A")], [(div, "INP")])
        self.assertEqual(bits.A, 0)
        self.assertEqual(div.OUTD, 0)
        # toggle
        self.c.do_write_register(bits_config.base, 0, bits_a_set_reg, 1)
        self.assertEqual(bits.A, 1)
        self.assertEqual(Block.bit_bus[bits_a_idx], 1)
        self.assertEqual(div.INP, 0)
        self.assertEqual(div.OUTN, 0)
        self.assertEqual(div.OUTD, 0)
        # do another tick and check it has propogated
        self.c.do_tick()
        self.assertEqual(div.INP, 1)
        self.assertEqual(div.OUTN, 0)
        self.assertEqual(div.OUTD, 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
