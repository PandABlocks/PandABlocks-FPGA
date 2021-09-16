#!/usr/bin/env python
try:
    from pkg_resources import require
except ImportError:
    pass
else:
    require("matplotlib")

import sys
import os
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np

from .ini_util import read_ini, timing_entries

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

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


def plot_bit(trace_items, names, offset, crossdist):
    for name, (tracex, tracey) in trace_items.items():
        if name in names:
            tracey = np.array([int(y, 0) for y in tracey])
            offset -= PULSE_HEIGHT + PLOT_OFFSET
            plt.plot(tracex, tracey + offset, linewidth=2)
            # add label
            legend_label(name, 0, tracey[0] + offset + PULSE_HEIGHT / 2., crossdist)
    return offset


def plot_pos(trace_items, names, offset, crossdist, ts):
    for name, (tracex, tracey) in trace_items.items():
        if name in names:
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
                plt.annotate(y, xy, color="white", horizontalalignment="left",
                             verticalalignment="center")

            # add label
            legend_label(name, 0, TRANSITION_HEIGHT / 2. + offset, crossdist)
    return offset


def make_timing_plot(path, section=None, xlabel="Timestamp (125MHz FPGA clock ticks)"):
    # Read the ini file and section
    ini = read_ini(os.path.join(ROOT, path))
    if not section:
        section = ini.sections()[0]

    # walk the inputs and outputs and add the names we're interested in
    in_names = []
    out_names = []
    pos_names = set()
    values = {}

    for ts, inputs, outputs in timing_entries(ini, section):
        for name, val in inputs.items():
            if name.startswith("TABLE_"):
                # Add table special
                name = "TABLE"
                pos_names.add(name)
            elif name.endswith("_L") or name.endswith("_H"):
                # Add times for time registers
                name = name[:-2]
                pos_names.add(name)
            else:
                val = int(val, 0)
            if name not in in_names:
                in_names.append(name)
            values.setdefault(name, set()).add(val)
        for name, val in outputs.items():
            if name != "TABLE_STROBES" and name not in out_names:
                out_names.append(name)
            values.setdefault(name, set()).add(int(val, 0))

    # constant traces should be pos_names
    for name, sval in values.items():
        if len(sval) == 1:
            pos_names.add(name)
        else:
            for val in sval:
                if val not in (0, 1):
                    pos_names.add(name)
                    break

    # sort the traces into bit and pos traces
    bit_traces = OrderedDict()
    pos_traces = OrderedDict()

    for name in in_names + out_names:
        if name in pos_names:
            pos_traces[name] = ([], [])
        else:
            bit_traces[name] = ([], [])

    # fill in first point
    for name, (tracex, tracey) in bit_traces.items():
        tracex.append(0)
        tracey.append('0')

    # now populate traces
    table_count = 0
    capture_count = 0
    data_count = 0
    lohi = {}
    for ts, inputs, outputs in timing_entries(ini, section):
        for name, (tracex, tracey) in bit_traces.items():
            if name in inputs:
                tracex.append(ts)
                tracex.append(ts)
                tracey.append(tracey[-1])
                tracey.append(inputs[name])
            elif name in outputs:
                tracex.append(ts+1)
                tracex.append(ts+1)
                tracey.append(tracey[-1])
                tracey.append(outputs[name])
        for name, (tracex, tracey) in pos_traces.items():
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
                lohi[name + "_L"] = int(inputs[name + "_L"], 0)
                inputs[name] = lohi[name + "_L"] + \
                    (lohi.get(name + "_H", 0) << 32)
            elif name + "_H" in inputs:
                lohi[name + "_H"] = int(inputs[name + "_H"], 0)
                inputs[name] = lohi.get(name + "_L", 0) + \
                    (lohi[name + "_H"] << 32)
            if name in inputs:
                if not tracey or tracey[-1] != inputs[name]:
                    tracex.append(ts)
                    tracey.append(inputs[name])
            elif name in outputs:
                # TODO: change to PCAP_DATA
                if name == "DATA":
                    data_count += 1
                    if (data_count - 1) % capture_count == 0:
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

    for name, (tracex, tracey) in bit_traces.items():
        tracex.append(ts)
        tracey.append(tracey[-1])

    # half the width of the crossover in timestamp ticks
    crossdist = CROSS_PIXELS * ts / 1000.

    # now plot inputs
    offset = 0
    offset = plot_pos(pos_traces, in_names, offset, crossdist, ts)
    offset = plot_bit(bit_traces, in_names, offset, crossdist)

    # draw a line
    offset -= PLOT_OFFSET
    plt.plot([0, ts], [offset, offset], 'k--')

    # and now do outputs
    offset = plot_bit(bit_traces, out_names, offset, crossdist)
    offset = plot_pos(pos_traces, out_names, offset, crossdist, ts)

    plt.ylim(offset - PLOT_OFFSET, 0)
    # add a grid, title, legend, and axis label
    plt.title(section)
    plt.grid(axis="x")
    plt.xlabel(xlabel)
    # turn off ticks and labels for y
    plt.tick_params(left=False, right=False, labelleft=False)

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
    make_timing_plot(*sys.argv[1:])
