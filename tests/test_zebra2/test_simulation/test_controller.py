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

    def do_set_reg(self, blockname, blocknum, regname, val):
        config = Block.parser.blocks[blockname]
        reg, _ = config.registers[regname]
        self.c.do_write_register(config.base, blocknum, reg, val)

    def get_instance(self, blockname, blocknum=0):
        config = Block.parser.blocks[blockname]
        for (base, num, reg), (block, attr) in self.c.lookup.items():
            if base == config.base and num == blocknum:
                return block

    def test_clocks_set(self):
        clocks = self.get_instance("CLOCKS")
        clocks_a_idx = Block.parser.bit_bus["CLOCKS.OUTA"]
        self.assertEqual(clocks.A_PERIOD, 0)
        self.assertEqual(self.c.wakeups, [])
        self.assertEqual(clocks.OUTA, 0)
        # set 1s period
        s = int(1.0 / CLOCK_TICK + 0.5)
        self.do_set_reg("CLOCKS", 0, "A_PERIOD", s)
        # number of clockticks to reg set
        reg_ticks = (time.time() - self.c.start_time) / CLOCK_TICK
        self.assertEqual(clocks.A_PERIOD, s)
        self.assertEqual(len(self.c.wakeups), 1)
        # check wakeup scheduled for 0.5s from now
        self.assertAlmostEqual(
            self.c.wakeups[0][0], reg_ticks + s / 2, delta=10000)
        self.assertEqual(self.c.wakeups[0][1], clocks)
        self.assertEqual(self.c.wakeups[0][2], {})
        self.assertEqual(clocks.OUTA, 0)
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
        self.assertEqual(clocks.OUTA, 1)
        self.assertEqual(Block.bit_bus[clocks_a_idx], 1)

    def test_changing_inp(self):
        # get the div block, and set it enabled
        bits_one_idx = Block.parser.bit_bus["BITS.ONE"]
        div = self.get_instance("DIV", 0)
        self.do_set_reg("DIV", 0, "ENABLE", bits_one_idx)
        self.assertEqual(div.ENABLE, 1)
        # get the bits block
        bits = self.get_instance("BITS", 0)
        bits_outa_idx = Block.parser.bit_bus["BITS.OUTA"]
        # check disconnected
        self.assertEqual(div.INP, 0)
        # connect to BITS.OUTA
        self.do_set_reg("DIV", 0, "INP", bits_outa_idx)
        self.assertEqual(div.INP, 0)
        self.assertEqual(self.c.listeners[(bits, "OUTA")], [(div, "INP")])
        self.assertEqual(bits.OUTA, 0)
        self.assertEqual(div.OUTD, 0)
        # toggle
        self.do_set_reg("BITS", 0, "A", 1)
        self.assertEqual(bits.OUTA, 1)
        self.assertEqual(Block.bit_bus[bits_outa_idx], 1)
        self.assertEqual(div.INP, 0)
        self.assertEqual(div.OUTN, 0)
        self.assertEqual(div.OUTD, 0)
        # Check that there is a wakeup queued
        self.assertEqual(len(self.c.wakeups), 1)
        # do another tick and check it has propogated
        self.c.do_tick()
        self.assertEqual(div.INP, 1)
        self.assertEqual(div.OUTN, 0)
        self.assertEqual(div.OUTD, 1)

    def test_delay(self):
        # get the div blocks and set them enabled
        bits_one_idx = Block.parser.bit_bus["BITS.ONE"]
        div1 = self.get_instance("DIV", 0)
        div2 = self.get_instance("DIV", 1)
        self.do_set_reg("DIV", 0, "ENABLE", bits_one_idx)
        self.do_set_reg("DIV", 1, "ENABLE", bits_one_idx)
        self.assertEqual(div1.ENABLE, 1)
        self.assertEqual(div2.ENABLE, 1)
        # get the bits block
        bits = self.get_instance("BITS", 0)
        bits_outa_idx = Block.parser.bit_bus["BITS.OUTA"]
        # check disconnected
        self.assertEqual(div1.INP, 0)
        # connect to BITS.OUTA
        self.do_set_reg("DIV", 0, "INP", bits_outa_idx)
        self.do_set_reg("DIV", 1, "INP", bits_outa_idx)
        self.assertEqual(div1.INP, 0)
        self.assertEqual(div2.INP, 0)
        self.assertEqual(self.c.listeners[(bits, "OUTA")],
                         [(div1, "INP"), (div2, "INP")])
        # Add a delay on the second
        self.do_set_reg("DIV", 1, "INP_DLY", 4)
        self.assertEqual(self.c.delays, {(div2, "INP"): 4})
        self.assertEqual(bits.OUTA, 0)
        self.assertEqual(div1.OUTD, 0)
        self.assertEqual(div2.OUTD, 0)
        # toggle
        self.do_set_reg("BITS", 0, "A", 1)
        self.assertEqual(bits.OUTA, 1)
        self.assertEqual(Block.bit_bus[bits_outa_idx], 1)
        self.assertEqual(div1.INP, 0)
        self.assertEqual(div1.OUTN, 0)
        self.assertEqual(div1.OUTD, 0)
        # check that there are two wakeups queued
        self.assertEqual(len(self.c.wakeups), 2)
        self.assertEqual(self.c.wakeups[0][1], div1)
        self.assertEqual(self.c.wakeups[1][1], div2)
        self.assertEqual(self.c.wakeups[1][0] - self.c.wakeups[0][0], 4)
        # do another tick and check it has propogated
        self.c.do_tick()
        self.assertEqual(div1.INP, 1)
        self.assertEqual(div1.OUTN, 0)
        self.assertEqual(div1.OUTD, 1)
        self.assertEqual(div2.INP, 0)
        self.assertEqual(div2.OUTN, 0)
        self.assertEqual(div2.OUTD, 0)
        # And again for the delayed
        self.c.do_tick()
        self.assertEqual(div1.INP, 1)
        self.assertEqual(div1.OUTN, 0)
        self.assertEqual(div1.OUTD, 1)
        self.assertEqual(div2.INP, 1)
        self.assertEqual(div2.OUTN, 0)
        self.assertEqual(div2.OUTD, 1)

if __name__ == '__main__':
    unittest.main(verbosity=2)
