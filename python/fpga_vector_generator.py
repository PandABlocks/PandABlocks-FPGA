#!/bin/env dls-python

from pkg_resources import require
require("numpy")
import sys
import os

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "python"))

from zebra2.simulation.block import Block
from zebra2.sequenceparser import SequenceParser

# and our parser dir is
parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "tests", "sim_sequences")
fpga_dir = os.path.join(
    os.path.dirname(__file__), "..", "build",  "fpga_sequences")
Block.load_config(os.path.join(os.path.dirname(__file__), '..', 'config_d'))

# Time between SIM_RESET being set high and the next test starting
RESET_DEADTIME = 100


class FpgaSequence(object):
    def __init__(self, parser, block, fpga_dir):
        self.parser = parser
        self.block = block
        self.fpga_dir = fpga_dir
        # field types
        config_block = Block.parser.blocks[block.upper()]
        # Get the column headings
        self.bus_in = ["TS", "SIM_RESET"]
        self.bus_out = ["TS"]
        self.reg_in = ["TS"]
        self.reg_out = ["TS"]
        # Add registers
        for name, (_, field) in config_block.registers.items():
            if field.typ.endswith("_mux"):
                self.bus_in.append(name)
            elif field.cls == "read":
                self.reg_out.append(name)
            else:
                self.reg_in.append(name)
                self.reg_in.append(name + "_WSTB")
        # Add outputs
        for name, (_, field) in config_block.outputs.items():
            if field.cls != "ext_out":
                self.bus_out.append(name)
        # Add PCAP registers if we are a pcap block
        if block == "pcap":
            reg_block = Block.parser.blocks["*REG"]
            for name in reg_block.registers:
                if name.startswith("PCAP_"):
                    self.reg_in.append(name[len("PCAP_"):])
            self.bus_out += ["DATA", "DATA_WSTB", "ERROR"]
        self.make_lines()

    def write(self):
        # Write the lines
        try:
            os.makedirs(self.fpga_dir)
        except OSError:
            pass
        for name in ["bus_in", "bus_out", "reg_in", "reg_out"]:
            f = open(os.path.join(
                self.fpga_dir, "%s_%s.txt" % (self.block, name)), "w")
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

    def set_wstb(self,ts, previous, current):
        changes = {}
        for name in self.reg_in + ["DATA"]:
            if current.get(name, 0) != previous.get(name, 0):
                changes.update({name + "_WSTB": 1}),
            else:
                changes.update({name + "_WSTB": 0})
        return changes

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
            previous = {}
            self.add_line(ts_off, dict(SIM_RESET=1))
            ts_off += RESET_DEADTIME
            # start the sequence
            for ts in sequence.inputs:
                previous.update(current)
                current.update(sequence.inputs[ts])
                current.update(sequence.outputs[ts])
                current.update(self.set_wstb(ts, previous, current))
                self.add_line(ts + ts_off, current)
            ts_off += ts + 1


def generate_fpga_test_vectors():
    sequences = []
    for fname in os.listdir(parser_dir):
        if fname.endswith(".seq"):
            parser = SequenceParser(os.path.join(parser_dir, fname))
            for seq in parser.sequences:
                sequences.append((fname.split(".")[0], seq))
            # Write the FPGA sequences
            FpgaSequence(parser, fname.split(".")[0], fpga_dir).write()

if __name__ == '__main__':
    generate_fpga_test_vectors()
