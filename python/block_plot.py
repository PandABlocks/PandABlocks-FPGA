#!/bin/env dls-python
from pkg_resources import require
require("matplotlib")
require("numpy")

import sys
import os
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np

from zebra2.sequenceparser import SequenceParser
from zebra2.configparser import ConfigParser


TRANSITION_HEIGHT = 0.6
PULSE_HEIGHT = 1.0
PLOT_OFFSET = 0.25
CROSS_PIXELS = 8
TOP_HEIGHT = 0.6
BOTTOM_HEIGHT = 1.0
VERTICAL_STRETCH = 0.5

# add our parser and config dirs
parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "tests", "sim_sequences")
config_dir = os.path.join( os.path.dirname(__file__), "..", "config_d")


def legend_label(text, x, y, off):
    plt.annotate(text, xy=(x, y), xytext=(x-off, y),
                 horizontalalignment="right", verticalalignment="center")

def plot_bit(trace_items, offset, crossdist):
    for name, (tracex, tracey) in trace_items:
        tracey = np.array(tracey)
        offset -= PULSE_HEIGHT + PLOT_OFFSET
        plt.plot(tracex, tracey + offset, linewidth=2)
        # add label
        legend_label(name, 0, tracey[0] + offset + PULSE_HEIGHT / 2., crossdist)
    return offset

def plot_pos(trace_items, offset, crossdist, ts):
    for name, (tracex, tracey) in trace_items:
        offset -= TRANSITION_HEIGHT + PLOT_OFFSET
        crossx = [0]
        top = [offset + TRANSITION_HEIGHT]
        bottom = [offset]
        for i, x in enumerate(tracex):
            # crossover start
            crossx.append(x - crossdist)
            top.append(top[-1])
            bottom.append(bottom[-1])
            # crossover end
            crossx.append(x + crossdist)
            top.append(bottom[-1])
            bottom.append(top[-2])
        # add end point
        crossx.append(ts)
        top.append(top[-1])
        bottom.append(bottom[-1])

        lines = plt.plot(crossx, top)
        plt.plot(crossx, bottom, color=lines[0].get_color())
        plt.fill_between(crossx, top, bottom, color=lines[0].get_color())
        for x, y in zip(tracex, tracey):
            xy = (crossdist + x, TRANSITION_HEIGHT / 2. + offset)
            plt.annotate(str(y), xy, color="white", horizontalalignment="left",
                         verticalalignment="center")

        # add label
        legend_label(name, 0, TRANSITION_HEIGHT / 2. + offset, crossdist)
    return offset

def make_block_plot(blockname, title):
    # Load the correct sequence file
    fname = blockname + ".seq"
    sparser = SequenceParser(os.path.join(parser_dir, fname))
    matches = [s for s in sparser.sequences if s.name == title]
    assert len(matches) == 1, 'Unknown title "%s" or multiple matches' % title
    sequence = matches[0]
    cparser = ConfigParser(config_dir)

    # make instance of block
    block = cparser.blocks[blockname.upper()]

    # walk the inputs and outputs and add the names we're interested in
    in_bits_names = set()
    out_bits_names = set()
    in_positions_names = set()
    out_positions_names = set()
    in_regs_names = set()
    out_regs_names = set()
    for ts in sequence.inputs:
        for name in sequence.inputs[ts].keys():
            # if there is a dot in the name, it's a bit or pos bus entry
            if "." in name:
                if name in cparser.bit_bus:
                    in_bits_names.add(name)
                    block.fields[name] = None
                elif name in cparser.pos_bus:
                    in_positions_names.add(name)
                    block.fields[name] = None
            elif block.name == "PCAP" and name in ["ARM", "DISARM"]:
                # Add in PCAP specials
                in_regs_names.add(name)
                block.fields[name] = None
            elif name.startswith("TABLE_"):
                # Add table special
                in_regs_names.add("TABLE")
            elif name.endswith("_L") or name.endswith("_H"):
                # Add times for time registers
                in_regs_names.add(name[:-2])
            elif name in block.registers:
                _, field = block.registers[name]
                if field.cls == "bit_mux":
                    in_bits_names.add(name)
                elif field.cls == "pos_mux":
                    in_positions_names.add(name)
                else:
                    in_regs_names.add(name)
        for name in sequence.outputs[ts].keys():
            if name in block.outputs:
                _, field = block.outputs[name]
                if field.cls == "bit_out":
                    out_bits_names.add(name)
                elif field.cls == "pos_out":
                    out_positions_names.add(name)
            elif block.name == "PCAP" and name == "OUT":
                # Add in PCAP output
                out_regs_names.add(name)
                block.fields[name] = None
            elif name != "TABLE_STROBES":
                out_regs_names.add(name)

    # sort the traces by block field order
    in_bits = OrderedDict()
    out_bits = OrderedDict()
    in_positions = OrderedDict()
    out_positions = OrderedDict()
    in_regs = OrderedDict()
    out_regs = OrderedDict()
    for name in block.fields:
        if name in in_bits_names:
            in_bits[name] = ([], [])
        elif name in out_bits_names:
            out_bits[name] = ([], [])
        elif name in in_positions_names:
            in_positions[name] = ([], [])
        elif name in out_positions_names:
            out_positions[name] = ([], [])
        elif name in in_regs_names:
            in_regs[name] = ([], [])
        elif name in out_regs_names:
            out_regs[name] = ([], [])

    def bit_traces():
        trace_items = in_bits.items() + out_bits.items()
        return trace_items

    def pos_traces():
        trace_items = in_positions.items() + out_positions.items() + \
            in_regs.items() + out_regs.items()
        return trace_items

    # fill in first point
    for name, (tracex, tracey) in bit_traces():
        tracex.append(0)
        tracey.append(0)

    # now populate traces
    table_count = 0
    capture_count = 0
    data_count = 0
    lohi = {}
    for ts in sequence.inputs:
        inputs = sequence.inputs[ts]
        outputs = sequence.outputs[ts]
        for name, (tracex, tracey) in bit_traces():
            if name in sequence.inputs[ts]:
                tracex.append(ts)
                tracex.append(ts)
                tracey.append(tracey[-1])
                tracey.append(inputs[name])
            elif name in sequence.outputs[ts]:
                tracex.append(ts+1)
                tracex.append(ts+1)
                tracey.append(tracey[-1])
                tracey.append(outputs[name])
        for name, (tracex, tracey) in pos_traces():
            if name == "TABLE":
                if "TABLE_START" in inputs:
                    inputs["TABLE"] = "load..."
                elif "TABLE_LENGTH" in inputs:
                    table_count += 1
                    inputs['TABLE'] = "T%d" % table_count
            elif name == "DATA":
                if "START_WRITE" in inputs:
                    capture_count = 0
                elif "WRITE" in inputs:
                    capture_count += 1
            elif name + "_L" in inputs:
                lohi[name + "_L"] = inputs[name + "_L"]
                inputs[name] = lohi[name + "_L"] + \
                    (lohi.get(name + "_H", 0) << 32)
            elif name + "_H" in inputs:
                lohi[name + "_H"] = inputs[name + "_H"]
                inputs[name] = lohi.get(name + "_L", 0) + \
                    (lohi[name + "_H"] << 32)
            if name in sequence.inputs[ts]:
                if block.name == "LUT" and name == "FUNC":
                    inputs[name] = hex(inputs[name])
                if not tracey or tracey[-1] != inputs[name]:
                    tracex.append(ts)
                    tracey.append(inputs[name])
            elif name in sequence.outputs[ts]:
                if block.name == "PCAP" and name == "OUT":
                    data_count += 1
                    if data_count % capture_count == 1:
                        outputs[name] = "Row%d" % (data_count / capture_count)
                    else:
                        # This is a subsequent count, ignore it
                        continue
                if not tracey or tracey[-1] != outputs[name]:
                    tracex.append(ts+1)
                    tracey.append(outputs[name])

    # add in an extra point at a major tick interval
    ts += 2
    if ts < 15:
        div = 2
    elif ts < 100:
        div = 5
    else:
        div = 10
    # round up to div
    off = ts % div
    if off:
        ts += div - off
    plt.xlim(0, ts)

    for name, (tracex, tracey) in bit_traces():
        tracex.append(ts)
        tracey.append(tracey[-1])

    # half the width of the crossover in timestamp ticks
    crossdist = CROSS_PIXELS * ts / 1000.

    # now plot inputs
    offset = 0
    offset = plot_pos(
        in_regs.items() + in_positions.items(), offset, crossdist, ts)
    offset = plot_bit(in_bits.items(), offset, crossdist)

    # draw a line
    offset -= PLOT_OFFSET
    plt.plot([0, ts], [offset, offset], 'k--')

    # and now do outputs
    offset = plot_bit(out_bits.items(), offset, crossdist)
    offset = plot_pos(
        out_positions.items() + out_regs.items(), offset, crossdist, ts)

    plt.ylim(offset - PLOT_OFFSET, 0)
    # add a grid, title, legend, and axis label
    plt.title(title)
    plt.grid(axis="x")
    plt.xlabel("Timestamp (125MHz FPGA clock ticks)")
    # turn off ticks and labels for y
    plt.tick_params(left='off', right='off', labelleft='off')

    # make it the right size
    fig = plt.gcf()
    total_height = TOP_HEIGHT + BOTTOM_HEIGHT + abs(offset)
    fig.set_size_inches(7.5, total_height * VERTICAL_STRETCH, forward=True)

    # set the margins
    top_frac = 1.0 - TOP_HEIGHT / total_height
    bottom_frac = BOTTOM_HEIGHT / total_height
    plt.subplots_adjust(left=0.18, right=0.98, top=top_frac, bottom=bottom_frac)

    plt.show()

if __name__ == "__main__":
    # test
    make_block_plot(sys.argv[1], sys.argv[2])
