#!/bin/env dls-python
import unittest
import sys
import os
# add our simulations dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "simulation"))
import sim_zebra2
from sim_zebra2.event import Event    
# and our sequence parser dir
parser_dir = os.path.join(os.path.dirname(__file__), "sim_zebra2_sequences")
sys.path.append(parser_dir)
from sequence_parser import SequenceParser


class SequenceTest(unittest.TestCase):

    def __init__(self, block, sequence):
        self.block = block
        self.sequence = sequence
        name = "%s: %s" % (block.title(), sequence.name)
        setattr(self, name, self.runTest)
        super(SequenceTest, self).__init__(name)

    def get_out_fields(self, block):
        bit_outs, pos_outs = {}, {}
        for name, field in block.fields.items():
            if field.cls == "bit_out":
                bit_outs[getattr(block, name)] = name
            elif field.cls == "pos_out":
                pos_outs[getattr(block, name)] = name
        return bit_outs, pos_outs

    def runTest(self):
        imp = __import__("sim_zebra2." + self.block, fromlist=[self.block.title()])
        # make instance of block
        block = getattr(imp, self.block.title())(1)
        # {num: name}
        bit_outs, pos_outs = self.get_out_fields(block)
        next_ts = None
        for ts in self.sequence.inputs:
            assert next_ts is None or ts <= next_ts, \
                "Expected ts %d, got ts %d" % (ts, next_ts)
            changes = self.sequence.inputs[ts]
            event = Event(ts)
            for name, val in changes.items():
                field = block.fields[name]
                if field.cls == "param" and field.typ == "bit_mux":
                    event.bit[getattr(block, name)] = val
                elif field.cls == "param" and field.typ == "pos_mux":
                    event.pos[getattr(block, name)] = val
                else:
                    event.reg[name] = val
            next_event = block.on_event(event)
            next_ts = next_event.ts
            # get the changes we were told about
            changes = {}
            for num, val in next_event.bit.items():
                changes[bit_outs[num]] = val 
            for num, val in next_event.pos.items():
                changes[pos_outs[num]] = val
            # check that these were mentioned
            self.assertDictContainsSubset(changes, self.sequence.outputs[ts])
            # now check that any not mentioned are the right value
            for name, val in self.sequence.outputs[ts].items():
                if name not in changes:
                    self.assertEqual(val, getattr(block, name))

def make_suite():
    suite = unittest.TestSuite()
    for fname in os.listdir(parser_dir):
        if fname.endswith(".seq"):
            parser = SequenceParser(os.path.join(parser_dir, fname))
            for seq in parser.sequences:
                testcase = SequenceTest(fname.split(".")[0], seq)
                suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    unittest.TextTestRunner(verbosity=2).run(make_suite())
