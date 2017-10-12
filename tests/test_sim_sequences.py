#!/bin/env dls-python

import sys
import os
from pkg_resources import require
require("numpy")
import unittest

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..",))

from common.python.pandablocks.block import Block
from common.python.pandablocks.sequenceparser import SequenceParser


import modules
module_dir = os.path.join(os.path.dirname(modules.__file__))

Block.load_config(os.path.join(os.path.dirname(__file__), '..', 'build', 'PandABox', 'config_d'))


def load_tests(loader=None, staqndard_tests=None, pattern=None):
    class SequenceTest(unittest.TestCase):

        def __init__(self, block, sequence):
            self.block = block
            self.sequence = sequence
            name = "%s: %s" % (block.title(), sequence.name)
            setattr(self, name, self.runTest)
            super(SequenceTest, self).__init__(name)

        def runTest(self):
            imp = __import__(
                self.block, fromlist=[self.block.title()])
            # make instance of block
            block = getattr(imp, self.block.title())()
            block.add_properties()
            block.bit_bus.fill(0)
            block.pos_bus.fill(0)
            # make default regs dict
            regs = {}
            bus = {}
            # get a list of all regs we are checking
            for ts in self.sequence.outputs:
                for name in self.sequence.outputs[ts]:
                    if name in block.config_block.outputs:
                        bus[name] = 0
                    else:
                        regs[name] = 0
            next_ts = None
            for ts in self.sequence.inputs:
                while next_ts is not None and next_ts < ts:
                    last_ts = next_ts
                    next_ts = block.on_changes(last_ts, {})
                    assert next_ts is None or next_ts > last_ts, \
                        "Expected next_ts %d > %d" % (next_ts, last_ts)
                    changes = dict((k, v) for k, v in block._changes.items()
                                   if k in regs or k in bus)
                    self.assertEqual(
                        changes, {},
                        "%d: Block changed %s" % (last_ts, changes))
                assert next_ts is None or ts <= next_ts, \
                    "Expected ts %d, got ts %d" % (ts, next_ts)
                changes = self.sequence.inputs[ts]

                # check that when _mux fields appear in changes that they actually
                # have changes, as our blocks expect this
                for name, val in changes.items():
                    # If there is a dot in the name, it's a bit or pos bus entry
                    if "[" in name:
                        idx = int(name.split("[")[1].split("]")[0])
                        if name.startswith("POS"):
                            Block.pos_bus[idx] = val
                        elif name.startswith("BIT"):
                            Block.bit_bus[idx] = val
                        else:
                            raise ValueError(
                                "Expected POS[n] or BIT[n], got %s" % name)
                        changes.pop(name)
                    else:
                        # Check that this is a valid field name
                        self.assertIn(name, dir(block.config_block))
                        field = block.config_block.fields.get(name, None)
                        if field and field.cls.endswith("_mux"):
                            current = bus.get(name, 0)
                            self.assertNotEqual(
                                val, current,
                                "%d: %s already set to %d" % (ts, name, val))
                            bus[name] = val

                # work out what changed and check they were mentioned
                next_ts = block.on_changes(ts, changes)

                if not hasattr(block, "_changes"):
                    block._changes = {}

                for name, val in block._changes.items():
                    # regs or bus outputs mentioned are checked
                    if name in self.sequence.outputs[ts]:
                        expected = self.sequence.outputs[ts][name]
                        bus[name] = val
                    # mentioned bus names are checked against prev value
                    elif name in bus:
                        expected = bus[name]
                    # mentioned reg names are checked against prev value
                    elif name in regs:
                        expected = regs[name]
                    # other changes are ignored
                    else:
                        continue
                    self.assertEquals(
                        val, expected,
                        "%d: Attr %s = %d != %d" % (ts, name, val, expected))

                # now check that any not mentioned are the right value
                for name, val in self.sequence.outputs[ts].items():
                    if name not in block._changes:
                        actual = getattr(block, name)
                        self.assertEqual(
                            val, actual,
                            "%d: Attr %s = %d != %d" % (ts, name, actual, val))

                block._changes.clear()

    suite = unittest.TestSuite()
    sequences = []
    for module in os.walk(module_dir):
        if 'sim' in module[1]:
            sim_sequence_path = os.path.join(module[0], 'sim')
            sys.path.insert(0, sim_sequence_path)
            for fname in os.listdir(sim_sequence_path):
                if fname.endswith(".seq"):
                    parser = SequenceParser(os.path.join(sim_sequence_path, fname))
                    for seq in parser.sequences:
                        sequences.append((fname.split(".")[0], seq))
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
    result = unittest.TextTestRunner(verbosity=2).run(load_tests())
    sys.exit(not result.wasSuccessful())
