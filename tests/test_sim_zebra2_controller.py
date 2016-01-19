#!/bin/env dls-python
import unittest
import sys
import os
import time

# Module import
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "python"))
from zebra2.simulation.zebra2 import Zebra2, Block, CLOCK_TICK


class Zebra2ControllerTest(unittest.TestCase):

    def setUp(self):
        config_dir = os.path.join(os.path.dirname(__file__), "..", "config_d")
        self.z = Zebra2(config_dir)

    def test_init(self):
        bits_base = Block.registers["BITS"].base
        for i, val in enumerate(self.z.bit_bus):
            if i == self.z.blocks[(bits_base, 0)].ONE:
                self.assertEqual(val, 1)
            else:
                self.assertEqual(val, 0)
        for i, val in enumerate(self.z.pos_bus):
            self.assertEqual(val, 0)

    def test_clocks_set(self):
        clocks_reg = Block.registers["CLOCKS"]
        clocks = self.z.blocks[(clocks_reg.base, 0)]
        clocks_period_reg_lo = int(clocks_reg.fields["A_PERIOD"].split()[0])
        self.assertEqual(clocks.A_PERIOD, 0)
        self.assertEqual(self.z.wakeups, [])
        self.assertEqual(self.z.bit_bus[clocks.A], 0)
        # set 1s period
        one_second = 1.0 / CLOCK_TICK
        data = (clocks_reg.base, 0,
            clocks_period_reg_lo, one_second)
        self.z.post(data)
        # number of clockticks to reg set
        reg_ticks = (time.time() - self.z.start_time) / CLOCK_TICK
        self.z.handle_events()
        self.assertEqual(clocks.A_PERIOD, one_second)
        self.assertEqual(len(self.z.wakeups), 1)
        # check wakeup scheduled for 0.5s from now
        self.assertAlmostEqual(
            self.z.wakeups[0][0], reg_ticks + one_second / 2, delta=10000)
        self.assertEqual(self.z.wakeups[0][1], clocks)
        self.assertEqual(self.z.bit_bus[clocks.A], 1)
        # handle another event
        start = time.time()
        self.z.handle_events()
        end = time.time()
        self.assertAlmostEqual(end-start, 0.5, delta=0.001)
        self.assertEqual(clocks.A_PERIOD, one_second)
        self.assertEqual(len(self.z.wakeups), 1)
        self.assertAlmostEqual(
            self.z.wakeups[0][0], reg_ticks + one_second, delta=10000)
        self.assertEqual(self.z.wakeups[0][1], clocks)
        self.assertEqual(self.z.bit_bus[clocks.A], 0)

    def test_changing_inp(self):
        div_reg = Block.registers["DIV"]
        div = self.z.blocks[(div_reg.base, 0)]
        bits_reg = Block.registers["BITS"]
        bits = self.z.blocks[(bits_reg.base, 0)]
        # check disconnected
        self.assertEqual(div.INP, bits.ZERO)
        # connect to BITS.A
        data = (div_reg.base, 0, int(div_reg.fields["INP"]), bits.A)
        self.z.post(data)
        self.z.handle_events()
        self.assertEqual(div.INP, bits.A)
        self.assertEqual(self.z.bit_listeners[bits.A], [div])
        self.assertEqual(self.z.bit_bus[bits.A], 0)
        self.assertEqual(self.z.bit_bus[div.OUTD], 0)
        # toggle
        data = (bits_reg.base, 0, int(bits_reg.fields["A_SET"]), 1)
        self.z.post(data)
        self.z.handle_events()
        self.assertEqual(self.z.bit_bus[bits.A], 1)
        self.assertEqual(self.z.bit_bus[div.OUTD], 1)



if __name__ == '__main__':
    unittest.main(verbosity=2)
