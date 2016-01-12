#!/bin/env dls-python

import sys
import os

from pkg_resources import require
require("matplotlib")

# add our simulations dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "simulation"))
parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "tests", "sim_zebra2_sequences")
sys.path.append(parser_dir)


from collections import OrderedDict
import itertools
import sim_zebra2
from sequence_parser import SequenceParser
import matplotlib.pyplot as plt
import numpy as np


# Load configuration
from sim_zebra2.block import Block
Block.load_config(os.path.join(os.path.dirname(__file__), '..', 'config_d'))


TRANSITION_HEIGHT = 0.6
PULSE_HEIGHT = 1.0
PLOT_OFFSET = 0.25
CROSS_PIXELS = 8
TOP_HEIGHT = 0.6
BOTTOM_HEIGHT = 1.0
VERTICAL_STRETCH = 0.5


def legend_label(text, x, y, off):
    plt.annotate(text, xy=(x, y), xytext=(x-off, y),
                 horizontalalignment="right", verticalalignment="center")

def plot_bit(trace_items, offset, crossdist):
    for name, (tracex, tracey) in trace_items:
        tracey = np.array(tracey)
        offset -= PULSE_HEIGHT + PLOT_OFFSET
        lines = plt.plot(tracex, tracey + offset, linewidth=2)
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
            xy = xy=(crossdist + x, TRANSITION_HEIGHT / 2. + offset)
            plt.annotate(str(y), xy, color="white", horizontalalignment="left",
                         verticalalignment="center")

        # add label
        legend_label(name, 0, TRANSITION_HEIGHT / 2. + offset, crossdist)
    return offset

def make_block_plot(block, title):
    # Load the correct sequence file
    fname = block + ".seq"
    parser = SequenceParser(os.path.join(parser_dir, fname))
    matches = [s for s in parser.sequences if s.name == title]
    assert len(matches) == 1, 'Unknown title "%s" or multiple matches' % title
    sequence = matches[0]
    imp = __import__("sim_zebra2." + block, fromlist=[block.title()])
    # make instance of block
    block = getattr(imp, block.title())(1)
    # do a plot
    in_bits_names = []
    out_bits_names = []
    in_positions_names = []
    out_positions_names = []
    in_regs_names = []
    out_regs_names = []
    # walk the inputs and outputs and add traces
    for ts in sequence.inputs:
        for name in sequence.inputs[ts].keys():
            if name not in block.fields:
                in_regs_names.append(name)
            else:
                field = block.fields[name]
                if field.cls == "param" and field.typ == "bit_mux":
                    in_bits_names.append(name)
                elif field.cls == "param" and field.typ == "pos_mux":
                    in_positions_names.append(name)
                else:
                    in_regs_names.append(name)
        for name in sequence.outputs[ts].keys():
            if name not in block.fields:
                out_regs_names.append(name)
            else:
                field = block.fields[name]
                if field.cls == "bit_out":
                    out_bits_names.append(name)
                elif field.cls == "pos_out":
                    out_positions_names.append(name)
                else:
                    out_regs_names.append(name)

    def bit_traces():
        trace_items = in_bits.items() + out_bits.items()
        return trace_items

    def pos_traces():
        trace_items = in_positions.items() + out_positions.items() + \
            in_regs.items() + out_regs.items()
        return trace_items

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

    # fill in first point
    for name, (tracex, tracey) in bit_traces():
        tracex.append(0)
        tracey.append(0)

    # now populate traces
    for ts in sequence.inputs:
        for name, (tracex, tracey) in bit_traces():
            if name in sequence.inputs[ts]:
                tracex.append(ts)
                tracex.append(ts)
                tracey.append(tracey[-1])
                tracey.append(sequence.inputs[ts][name])
            elif name in sequence.outputs[ts]:
                tracex.append(ts+1)
                tracex.append(ts+1)
                tracey.append(tracey[-1])
                tracey.append(sequence.outputs[ts][name])
        for name, (tracex, tracey) in pos_traces():
            if name in sequence.inputs[ts]:
                if not tracey or tracey[-1] != sequence.inputs[ts][name]:
                    tracex.append(ts)
                    tracey.append(sequence.inputs[ts][name])
            elif name in sequence.outputs[ts]:
                if not tracey or tracey[-1] != sequence.outputs[ts][name]:
                    tracex.append(ts+1)
                    tracey.append(sequence.outputs[ts][name])

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
