#!/bin/env python

import sys
import os

# add our simulations dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "simulation"))
# and our sequence parser dir
parser_dir = os.path.join(os.path.dirname(__file__), "sim_zebra2_sequences")
sys.path.append(parser_dir)

import unittest
import sim_zebra2
from sim_zebra2.event import Event
from sim_zebra2.block import Block
from sequence_parser import SequenceParser, FpgaSequence

Block.load_config(os.path.join(os.path.dirname(__file__), '..', 'config_d'))


class SequenceTest(unittest.TestCase):

    def __init__(self, block, sequence):
        self.block = block
        self.sequence = sequence
        name = "%s: %s" % (block.title(), sequence.name)
        setattr(self, name, self.runTest)
        super(SequenceTest, self).__init__(name)

    def runTest(self):
        imp = __import__(
            "sim_zebra2." + self.block, fromlist=[self.block.title()])
        # make instance of block
        block = getattr(imp, self.block.title())(1)
        # set muxes to increasing unique indexes
        i = 0
        for name, field in block.fields.items():
            if field.typ.endswith("_mux"):
                setattr(block, name, i)
                i += 1
        # make default regs dict
        regs = {}
        for ts in self.sequence.outputs:
            for name in self.sequence.outputs[ts]:
                field = block.fields[name]
                if not field.cls.endswith("_out"):
                    regs[name] = 0
        # {num: name}
        next_ts = None
        bus = {}
        for ts in self.sequence.inputs:
            assert next_ts is None or ts <= next_ts, \
                "Expected ts %d, got ts %d" % (ts, next_ts)
            changes = self.sequence.inputs[ts]
            event = Event(ts)
            for name, val in changes.items():
                field = block.fields.get(name, None)
                if field and field.typ.endswith("_mux"):
                    current = bus.get(name, 0)
                    self.assertNotEqual(
                        val, current,
                        "%d: %s already set to %d" % (ts, name, val))
                    if field.typ == "bit_mux":
                        event_dict = event.bit
                    else:
                        event_dict = event.pos
                    event_dict[getattr(block, name)] = val
                    bus[name] = val
                else:
                    event.reg[name] = val
            next_event = block.on_event(event)
            next_ts = next_event.ts
            # get the changes we were told about
            changes = {}
            for num, val in next_event.bit.items():
                changes[block.bit_outs[num]] = val
            for num, val in next_event.pos.items():
                changes[block.pos_outs[num]] = val
            # check that these were mentioned
            for name, val in changes.items():
                if name in self.sequence.outputs[ts]:
                    expected = self.sequence.outputs[ts][name]
                    bus[name] = val
                else:
                    expected = bus.get(name, 0)
                self.assertEquals(
                    val, expected,
                    "%d: Out %s = %d != %d" % (ts, name, val, expected))

            # update regs with any values not in changes
            for name, val in self.sequence.outputs[ts].items():
                if name not in changes:
                    regs[name] = val

            # now check that any not mentioned are the right value
            for name, val in regs.items():
                field = block.fields[name]
                if field.cls.endswith("_out"):
                    self.fail("%d: Didn't produce output %s = %d" %
                              (ts, name, val))
                actual = getattr(block, name)
                self.assertEqual(
                    val, actual,
                    "%d: Reg %s = %d != %d" % (ts, name, actual, val))
                regs[name] = val


def make_suite():
    suite = unittest.TestSuite()
    sequences = []
    for fname in os.listdir(parser_dir):
        if fname.endswith(".seq"):
            parser = SequenceParser(os.path.join(parser_dir, fname))
            for seq in parser.sequences:
                sequences.append((fname.split(".")[0], seq))
            # Write the FPGA sequences
            FpgaSequence(parser, fname.split(".")[0]).write()
    # These are the tests that start with !
    marks = [s for s in sequences if s[1].mark]
    if marks:
        # If we have any marked, only run those
        sequences = marks
    for name, seq in sequences:
        testcase = SequenceTest(name, seq)
        suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(make_suite())
    sys.exit(not result.wasSuccessful())
