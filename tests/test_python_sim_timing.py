#!/usr/bin/env python

try:
    from pkg_resources import require
except ImportError:
    pass
else:
    require("numpy")

import sys
import os
import imp

import unittest

from common.python.ini_util import read_ini, timing_entries

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODULES = os.path.join(ROOT, "modules")


def load_tests(loader=None, standard_tests=None, pattern=None):
    class SequenceTest(unittest.TestCase):

        def __init__(self, module_path, timing_ini, timing_section):
            self.module_path = module_path
            self.timing_ini = timing_ini
            self.timing_section = timing_section
            # The scope of this timing test should be a block ini
            try:
                block_ini_name = timing_ini.get(".", "scope")
            except Exception as e:
                raise ValueError(
                    "Can't find section '.' with entry 'scope' in module %s" % (
                        module_path))
            assert block_ini_name.endswith(".block.ini"), \
                "Can only test timing with scope <block>.block.ini, not %s" % (
                    block_ini_name)
            self.block_ini = read_ini(os.path.join(module_path, block_ini_name))
            # Make a nice name for console output
            self.block_name = block_ini_name[:-len(".block.ini")]
            test_name = "%s: %s" % (self.block_name.title(), timing_section)
            setattr(self, test_name, self.runTest)
            super(SequenceTest, self).__init__(test_name)

        def runTest(self):
            # Load <block>_sim.py into common.python.<block>_sim
            file, pathname, description = imp.find_module(
                self.block_name + "_sim", [self.module_path])
            mod = imp.load_module(
                "common.python." + self.block_name,
                file, pathname, description)
            # Make instance of <Block>Simulation
            block = getattr(mod, self.block_name.title() + "Simulation")()
            # Start prodding the block and checking its outputs
            next_ts = None
            for ts, inputs, outputs in timing_entries(
                    self.timing_ini, self.timing_section):
                while next_ts is not None and next_ts < ts:
                    last_ts = next_ts
                    next_ts = block.on_changes(last_ts, {})
                    assert next_ts is None or next_ts > last_ts, \
                        "Expected next_ts %d > %d" % (next_ts, last_ts)
                    self.assertEqual(
                        block.changes, {},
                        "%d: Block unexpectedly changed %s" % (
                            last_ts, block.changes))
                assert next_ts is None or ts <= next_ts, \
                    "Expected ts %d, got ts %d" % (ts, next_ts)

                # Tell the block what changed (as ints, parsing 0x correctly)
                changes = {}
                for name, value in inputs.items():
                    # Table address is a path, so keep as a string, otherwise
                    # convert to int parsing 0x correctly
                    if name != "TABLE_ADDRESS":
                        value = int(value, 0)

                    # If there is a [ in the name, it's a bit or pos bus entry
                    if "[" in name:
                        idx = int(name.split("[")[1].split("]")[0])
                        if name.startswith("POS"):
                            block.pos_bus[idx] = value
                            block.pos_change.append(idx)
                        elif name.startswith("BIT"):
                            block.bit_bus[idx] = value
                        else:
                            raise ValueError(
                                "Expected POS[n] or BIT[n], got %s" % name)
                    else:
                        assert hasattr(block, name), \
                            "Block %s doesn't have attr %s" % (
                                self.block_name, name)
                        changes[name] = value

                next_ts = block.on_changes(ts, changes)
                if block.changes is None:
                    block.changes = {}

                # Check that all changes are expected
                for name, actual in block.changes.items():
                    if name in outputs:
                        # Expected an output change, check it's right
                        expected = int(outputs[name])
                        assert actual == expected, \
                            "%d: Attr %s = %d != %d" % (
                                ts, name, actual, expected)
                    else:
                        # It might have been an input
                        assert name in changes, \
                            "%d: Attr %s unexpectedly changed to %d" % (
                                ts, name, actual)
                        # We changed it, check it's the value we set
                        assert actual == changes[name], \
                            "%d: Attr %s = %d != %d" % (
                                ts, name, actual, changes[name])

                # Check all outputs have correct field values
                for name in outputs:
                    expected = int(outputs[name], 0)
                    actual = getattr(block, name)
                    assert actual == expected, \
                        "%d: Attr %s = %d != %d" % (
                            ts, name, actual, expected)

                block.changes.clear()

    suite = unittest.TestSuite()
    sections = []
    for d in os.listdir(MODULES):
        module = os.path.join(MODULES, d)
        for f in os.listdir(module):
            if f.endswith(".timing.ini"):
                ini = read_ini(os.path.join(module, f))
                for section in ini.sections():
                    if section != ".":
                        sections.append((module, ini, section))

    # Also run the PCAP test
    module = os.path.join(ROOT, "targets/PandABox/blocks/pcap")
    for f in os.listdir(module):
        if f.endswith(".timing.ini"):
            ini = read_ini(os.path.join(module, f))
            for section in ini.sections():
                if section != ".":
                    sections.append((module, ini, section))

    # These are the tests that start with !
    marks = [(f, i, s) for (f, i, s) in sections if s.startswith("!")]
    if marks:
        # If we have any marked, only run those
        sections = marks
    for module, ini, section in sections:
        testcase = SequenceTest(module, ini, section)
        suite.addTest(testcase)
    return suite


if __name__ == '__main__':
    # Need numpy for block simulations
    result = unittest.TextTestRunner(verbosity=2).run(load_tests())
    sys.exit(not result.wasSuccessful())
