#!/bin/env python
import unittest
import sys
import os
# add our simulations dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "simulation"))
import sim_zebra2
from sim_zebra2.event import Event
# and our sequence parser dir
parser_dir = os.path.join(os.path.dirname(__file__), "sim_zebra2_sequences")
fpga_dir = os.path.join(os.path.dirname(__file__), "fpga_sequences")
sys.path.append(parser_dir)
from sequence_parser import SequenceParser


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
            if field.cls == "param" and field.typ \
                    and field.typ.endswith("_mux"):
                setattr(block, name, i)
                i += 1
        # {num: name}
        next_ts = None
        bus = {}
        for ts in self.sequence.inputs:
            assert next_ts is None or ts <= next_ts, \
                "Expected ts %d, got ts %d" % (ts, next_ts)
            changes = self.sequence.inputs[ts]
            event = Event(ts)
            for name, val in changes.items():
                field = block.fields[name]
                if field.cls == "param" and field.typ \
                        and field.typ.endswith("_mux"):
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
                else:
                    expected = bus.get(name, 0)
                self.assertEquals(
                    val, expected,
                    "%d: Out %s = %d != %d" % (ts, name, val, expected))
            bus.update(changes)

            # now check that any not mentioned are the right value
            for name, val in self.sequence.outputs[ts].items():
                if name not in changes:
                    actual = getattr(block, name)
                    self.assertEqual(
                        val, actual,
                        "%d: Reg %s = %d != %d" % (ts, name, actual, val))

        # if we were successful, then write the "All" test to FPGA
        if self.sequence.name == "All":
            # Get the column headings
            bus_in = []
            bus_out = []
            reg_in = []
            reg_out = []

            current = {}
            for name, field in block.fields.items():
                if field.cls == "param" and field.typ and field.typ.endswith("_mux"):
                    bus_in.append(name)
                elif field.cls.endswith("_out"):
                    bus_out.append(name)
                elif field.cls == "read":
                    reg_out.append(name)
                else:
                    reg_in.append(name)
            # Write the lines
            try:
                os.makedirs(fpga_dir)
            except OSError:
                pass
            fbus_in = open(
                os.path.join(fpga_dir, self.block + "_bus_in.txt"), "w")
            fbus_out = open(
                os.path.join(fpga_dir, self.block + "_bus_out.txt"), "w")
            freg_in = open(
                os.path.join(fpga_dir, self.block + "_reg_in.txt"), "w")
            freg_out = open(
                os.path.join(fpga_dir, self.block + "_reg_out.txt"), "w")
            fbus_in.write("\t".join(["TS"] + bus_in) + "\n")
            fbus_out.write("\t".join(["TS"] + bus_out) + "\n")
            freg_in.write("\t".join(["TS"] + reg_in) + "\n")
            freg_out.write("\t".join(["TS"] + reg_out) + "\n")
            for ts in self.sequence.inputs:
                current.update(self.sequence.inputs[ts])
                current.update(self.sequence.outputs[ts])

                lbus_in = [str(current.get(name, 0)) for name in bus_in]
                lbus_out = [str(current.get(name, 0)) for name in bus_out]
                lreg_in = [str(current.get(name, 0)) for name in reg_in]
                lreg_out = [str(current.get(name, 0)) for name in reg_out]

                fbus_in.write("\t".join([str(ts)] + lbus_in) + "\n")
                fbus_out.write("\t".join([str(ts+1)] + lbus_out) + "\n")
                freg_in.write("\t".join([str(ts)] + lreg_in) + "\n")
                freg_out.write("\t".join([str(ts+1)] + lreg_out) + "\n")

            fbus_in.close()
            fbus_out.close()
            freg_in.close()
            freg_out.close()


def make_suite():
    suite = unittest.TestSuite()
    sequences = []
    for fname in os.listdir(parser_dir):
        if fname.endswith(".seq"):
            parser = SequenceParser(os.path.join(parser_dir, fname))
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
    unittest.TextTestRunner(verbosity=2).run(make_suite())
