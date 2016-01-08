#!/bin/env python

from collections import OrderedDict
import sys
import os

from sim_zebra2.block import Block


class SequenceParser(object):

    def __init__(self, f):
        lines = open(f).readlines()
        self.sequences = []
        for line in lines:
            if line.startswith("$"):
                name = line[1:].strip()
                if name.startswith("!"):
                    mark = True
                    name = name[1:].strip()
                else:
                    mark = False
                self.sequences.append(Sequence(name, mark))
            elif not line.startswith("#"):
                try:
                    self.parse_line(line)
                except Exception, e:
                    raise ValueError(e.message + "\nLine: %s" % line)

    def parse_line(self, line):
        line = line.strip()
        if line:
            split = line.split(":")
            ts = int(split[0].strip())
            inputs = self.parse_dict(split[1])
            if len(split) > 2:
                outputs = self.parse_dict(split[2])
            else:
                outputs = {}
            self.sequences[-1].add_line(ts, inputs, outputs)

    def parse_dict(self, s):
        d = {}
        s = s.strip()
        if s:
            for t in s.split(","):
                t = t.strip()
                k, v = t.split("=")
                # detect 0x prefix automatically
                d[k.strip()] = int(v.strip(), 0)
        return d


class Sequence(object):

    def __init__(self, name, mark=False):
        # These are {ts: {name: new_val}}
        self.name = name
        self.mark = mark
        self.inputs = OrderedDict()
        self.outputs = OrderedDict()

    def add_line(self, ts, inputs, outputs):
        assert ts not in self.inputs, \
            "Redefined ts %s" % ts
        if self.inputs:
            assert ts > self.inputs.keys()[-1], \
                "ts %s goes backwards" % ts
        self.inputs[ts] = inputs
        self.outputs[ts] = outputs


class FpgaSequence(object):
    def __init__(self, parser, block):
        self.parser = parser
        self.block = block
        # field types
        fields = Block.config[block.upper()].fields
        # Get the column headings
        self.bus_in = ["TS", "SIM_RESET"]
        self.bus_out = ["TS"]
        self.reg_in = ["TS"]
        self.reg_out = ["TS"]
        for name, field in fields.items():
            if field.typ.endswith("_mux"):
                self.bus_in.append(name)
            elif field.cls.endswith("_out"):
                self.bus_out.append(name)
            elif field.cls == "read":
                self.reg_out.append(name)
            else:
                self.reg_in.append(name)
        self.make_lines()

    def write(self):
        # Write the lines
        fpga_dir = os.path.join(
            os.path.dirname(__file__), "..", "fpga_sequences")
        try:
            os.makedirs(fpga_dir)
        except OSError:
            pass
        for name in ["bus_in", "bus_out", "reg_in", "reg_out"]:
            f = open(os.path.join(
                fpga_dir, "%s_%s.txt" %(self.block, name)), "w")
            headings = getattr(self, name)
            f.write("\t".join(headings) + "\n")
            lines = getattr(self, name + "_lines")
            for line in lines:
                f.write("\t".join(line) + "\n")
            f.close()

    def add_line(self, ts, current):
        lbus_in = [str(current.get(name, 0)) for name in self.bus_in]
        lbus_out = [str(current.get(name, 0)) for name in self.bus_out]
        lreg_in = [str(current.get(name, 0)) for name in self.reg_in]
        lreg_out = [str(current.get(name, 0)) for name in self.reg_out]
        lbus_in[0] = str(ts)
        lbus_out[0] = str(ts+1)
        lreg_in[0] = str(ts)
        lreg_out[0] = str(ts+1)
        self.bus_in_lines.append(lbus_in)
        self.bus_out_lines.append(lbus_out)
        self.reg_in_lines.append(lreg_in)
        self.reg_out_lines.append(lreg_out)

    def make_lines(self):
        # make lines list
        self.bus_in_lines = []
        self.bus_out_lines = []
        self.reg_in_lines = []
        self.reg_out_lines = []
        # add an offset for each sequence
        ts_off = 0
        for sequence in self.parser.sequences:
            # reset simultion
            current = {}
            self.add_line(ts_off, dict(SIM_RESET=1))
            ts_off += 10
            # start the sequence
            for ts in sequence.inputs:
                current.update(sequence.inputs[ts])
                current.update(sequence.outputs[ts])
                self.add_line(ts + ts_off, current)
            ts_off += ts

# test
if __name__ == "__main__":
    # sequence file for block
    block = sys.argv[1]
    # parse sequence
    fname = os.path.join(os.path.dirname(__file__), block + ".seq")
    parser = SequenceParser(fname)
    # write fpga sequence to file
    FpgaSequence(parser, block).write()
