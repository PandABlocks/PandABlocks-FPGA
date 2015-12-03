#!/bin/env dls-python
from pkg_resources import require
require("matplotlib")
import sys
import os
from collections import OrderedDict
import itertools
# add our simulations dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "simulation"))
import sim_zebra2
# and our sequence parser dir
parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "tests", "sim_zebra2_sequences")
sys.path.append(parser_dir)
from sequence_parser import SequenceParser
import matplotlib.pyplot as plt
import numpy as np

TRANSITION_HEIGHT = 0.6
PULSE_HEIGHT = 1.0
PLOT_OFFSET = 0.25
CROSS_PIXELS = 8


def legend_label(text, x, y, off):
    plt.annotate(text, xy=(x, y), xytext=(x-off, y), 
                 horizontalalignment="right", verticalalignment="center")
    
def make_block_plot(block, title):
    # Load the correct sequence file
    fname = block + ".seq"
    parser = SequenceParser(os.path.join(parser_dir, fname))
    sequence = [s for s in parser.sequences if s.name == title][0]
    imp = __import__("sim_zebra2." + block, fromlist=[block.title()])
    # make instance of block
    block = getattr(imp, block.title())(1)
    # do a plot
    xs = []
    in_bits_names = []
    out_bits_names = []
    in_positions_names = []
    out_positions_names = []
    in_regs_names = []
    out_regs_names = []
    # walk the inputs and outputs and add traces
    for ts in sequence.inputs:
        for name in sequence.inputs[ts].keys():
            field = block.fields[name]
            if field.cls == "param" and field.typ == "bit_mux":
                in_bits_names.append(name)
            elif field.cls == "param" and field.typ == "pos_mux":
                in_positions_names.append(name)
            else:
                in_regs_names.append(name)
        for name in sequence.outputs[ts].keys():
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
            in_bits[name] = []
        elif name in out_bits_names:
            out_bits[name] = []
        elif name in in_positions_names:
            in_positions[name] = ([], [])
        elif name in out_positions_names:
            out_positions[name] = ([], [])
        elif name in in_regs_names:
            in_regs[name] = ([], [])
        elif name in out_regs_names:
            out_regs[name] = ([], [])

    # fill in first point
    xs.append(0)
    for name, trace in bit_traces():
        trace.append(0)

    # now populate traces
    for ts in sequence.inputs:
        xs.append(ts)
        xs.append(ts)
        for name, trace in bit_traces():
            trace.append(trace[-1])
            if name in sequence.inputs[ts]:
                trace.append(sequence.inputs[ts][name])
            elif name in sequence.outputs[ts]:
                trace.append(sequence.outputs[ts][name])
            else:
                trace.append(trace[-1])
        for name, (tracex, tracey) in pos_traces():
            if name in sequence.inputs[ts]:
                tracex.append(ts)
                tracey.append(sequence.inputs[ts][name])
            elif name in sequence.outputs[ts]:
                tracex.append(ts)
                tracey.append(sequence.outputs[ts][name])

    # add in an extra point at a major tick interval
    ts += 1
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
    
    xs.append(ts)
    for name, trace in bit_traces():
        trace.append(trace[-1])

    # array of xs
    xs = np.array(xs)
    crossdist = CROSS_PIXELS * ts / 1000.

    # now plot
    offset = 0
    for name, trace in bit_traces():
        trace = np.array(trace)
        offset -= PULSE_HEIGHT + PLOT_OFFSET
        lines = plt.plot(xs, trace + offset, linewidth=2)
        # add label
        legend_label(name, 0, trace[0] + offset, crossdist)

    # and now do regs
    for name, (tracex, tracey) in pos_traces():
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

    plt.ylim(offset - PLOT_OFFSET, 0)
    # add a grid, title, legend, and axis label
    plt.title(title)
    plt.grid(axis="x")
    plt.xlabel("Timestamp (125MHz FPGA clock ticks)")
    # turn off ticks and labels for y
    plt.tick_params(left='off', right='off', labelleft='off')
    
    # make it the right size
    fig = plt.gcf()
    fig.set_size_inches(7.5, abs(offset) * 0.6, forward=True)    
    plt.subplots_adjust(left=0.18, right=0.98, bottom=0.18)
    
    plt.show()

if __name__ == "__main__":
    # test
    make_block_plot("pulse", "Pulse stretching with no delay")
