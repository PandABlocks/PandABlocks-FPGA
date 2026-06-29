#!/usr/bin/env python
try:
    from pkg_resources import require
except ImportError:
    pass
else:
    require("matplotlib")

import argparse
import csv
import json
import os
import sys
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
    table_address_seen = False
    for ts, inputs, outputs in timing_entries(ini, section):
        if "TABLE_ADDRESS" in inputs:
            table_address_seen = True

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
                    if table_address_seen:
                        table_count += 1
                    table_address_seen = False
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

    # draw a line (follow the theme text colour so it shows on dark backgrounds)
    offset -= PLOT_OFFSET
    plt.plot([0, ts], [offset, offset], '--', color=plt.rcParams["text.color"])

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


# rcParams that recolour the plot for a dark page background. The traces keep
# their (theme-independent) colour-cycle colours; only text/axes/grid/separator
# need lightening, which these drive (the separator reads text.color above).
DARK_RC = {
    "text.color": "#d4d4d4",
    "axes.labelcolor": "#d4d4d4",
    "axes.edgecolor": "#d4d4d4",
    "xtick.color": "#d4d4d4",
    "ytick.color": "#d4d4d4",
    "grid.color": "#666666",
}


def render(path, out, section=None,
           xlabel="Timestamp (125MHz FPGA clock ticks)", dark=False):
    """Render one timing diagram to ``out`` (light by default, dark if asked).

    Backgrounds are transparent so the page colour shows through.
    """
    import matplotlib as mpl
    with mpl.rc_context(DARK_RC if dark else {}):
        plt.figure()
        make_timing_plot(path, section, xlabel)
        plt.savefig(out, transparent=True)
        plt.close()


# --- accompanying data tables (pcap/seq/pgen), ported from the old Sphinx -----
# directive. Each table is {"head": [rows], "body": [rows]} where a row is a
# list of [text, colspan] cells; the MyST directive turns these into tables.

def hex_or_int(val):
    """Convert a string (optionally 0x-prefixed) to an int."""
    val = val.strip()
    return int(val, 16) if val.startswith("0x") else int(val, 0)


def _cells(values):
    return [[v, 1] for v in values]


def _seq_table(title, data):
    hdr = "Repeats Condition Position Time A B C D E F Time A B C D E F".split()
    ncols = len(hdr)
    head = [
        [[title, ncols]],
        [["#", 1], ["Trigger", 2], ["Phase1", 1], ["Phase1 Outputs", 6],
         ["Phase2", 1], ["Phase2 Outputs", 6]],
        _cells(hdr),
    ]
    triggers = [
        "Immediate", "BITA=0", "BITA=1", "BITB=0", "BITB=1", "BITC=0", "BITC=1",
        "POSA>=POSITION", "POSA<=POSITION", "POSB>=POSITION", "POSB<=POSITION",
        "POSC>=POSITION", "POSC<=POSITION", "", "", ""]
    body = []
    for frame in range(len(data) // 4):
        w0 = data[0 + frame * 4]
        row = [w0 & 0xFFFF, triggers[w0 >> 16 & 0xF],
               data[1 + frame * 4], data[2 + frame * 4]]
        p1 = (w0 >> 20) & 0x3F
        row += [(p1 >> i) & 1 for i in range(6)]
        row.append(data[3 + frame * 4])
        p2 = (w0 >> 26) & 0x3F
        row += [(p2 >> i) & 1 for i in range(6)]
        body.append(_cells(row))
    return {"head": head, "body": body}


def _seq_tables(ini, section, module_dir):
    alltables = []
    table_address = ""
    seen = False
    for ts, inputs, outputs in timing_entries(ini, section):
        if "TABLE_LENGTH" in inputs and seen:
            seen = False
            fp = os.path.join(module_dir, "tests_assets", "%s.txt" % table_address)
            lines = list(open(fp))[1:]
            alltables.append([hex_or_int(line) for line in lines])
        if "TABLE_ADDRESS" in inputs:
            seen = True
            table_address = inputs["TABLE_ADDRESS"]
    return [_seq_table("T%d" % (i + 1), st) for i, st in enumerate(alltables)]


def _pgen_tables(ini, section, module_dir):
    out = []
    for ts, inputs, outputs in timing_entries(ini, section):
        if "TABLE_ADDRESS" in inputs:
            fp = os.path.join(module_dir, "tests_assets",
                              "%s.txt" % inputs["TABLE_ADDRESS"])
            with open(fp) as f:
                rows = list(csv.DictReader(f, delimiter="\t"))
            keys = list(rows[0].keys())
            head = [[["T%d" % (len(out) + 1), len(keys)]], _cells(keys)]
            body = [_cells(r.values()) for r in rows]
            out.append({"head": head, "body": body})
    return out


def _pcap_tables(ini, section):
    data_header = []
    for ts, inputs, outputs in timing_entries(ini, section):
        for name in inputs:
            if name == "START_WRITE":
                data_header = []
            elif name == "WRITE":
                v = inputs[name]
                data_header.append("0x%X" % (int(v, 16) if "x" in v else int(v, 0)))
    if not data_header:
        return []
    # (The Sphinx version had a "BITS" branch using an undefined `cparser`; it
    # was dead code — header names are always hex strings — so it is dropped.)
    table_hdr = ["Row"]
    bit_extracts = []
    for name in data_header:
        if name.endswith("_H"):
            bit_extracts.append(name[:-2])
        else:
            bit_extracts.append(None)
            table_hdr.append(name)
    body = []
    r, row, high, i = 0, [0], {}, 0
    for ts, inputs, outputs in timing_entries(ini, section):
        if "DATA" not in outputs:
            continue
        v = outputs["DATA"]
        data = int(v, 16) if "x" in v else int(v, 0)
        extract = bit_extracts[i]
        if isinstance(extract, str):
            high[extract] = data
        else:
            row.append(data)
        i += 1
        if i >= len(bit_extracts):
            for name, val in high.items():
                row[table_hdr.index(name)] += val << 32
            body.append(_cells(row))
            r, row, high, i = r + 1, [r + 1], {}, 0
    return [{"head": [_cells(table_hdr)], "body": body}]


def make_tables(path, section=None):
    """Return the data tables accompanying the diagram, by module convention.

    Mirrors the pcap/seq/pgen tables the old Sphinx directive auto-generated.
    Returns ``[]`` for modules that have none.
    """
    full = os.path.join(ROOT, path)
    ini = read_ini(full)
    if section is None:
        section = ini.sections()[0]
    module_dir = os.path.dirname(full)
    module = os.path.basename(module_dir)
    if module == "pcap":
        return _pcap_tables(ini, section)
    if module == "seq":
        return _seq_tables(ini, section, module_dir)
    if module == "pgen":
        return _pgen_tables(ini, section, module_dir)
    return []


def main(argv=None):
    """Command-line entry point: render a timing diagram to image file(s).

    Keeps relative imports, so run it as a module from the repo root::

        python -m common.python.timing_plot \\
            modules/counter/counter_documentation.timing.ini \\
            --section "Count Up only when enabled" --out counter.svg

    Pass ``--dark-out`` as well to also render a dark-theme variant in the same
    process (one matplotlib import). This same entry point is shelled out to by
    the MyST ``timing_plot`` directive (docs/_plugins/timing-plot.mjs).
    """
    parser = argparse.ArgumentParser(
        description="Render a PandABlocks timing diagram from an ini section.")
    parser.add_argument(
        "path", help="path to the .timing.ini (relative to the repo root, "
        "or absolute)")
    parser.add_argument(
        "--section", default=None,
        help="ini section to plot (default: the first section)")
    parser.add_argument(
        "--xlabel", default="Timestamp (125MHz FPGA clock ticks)",
        help="x-axis label")
    parser.add_argument(
        "--out", default=None,
        help="light-theme output image file; the extension picks the format "
        "(e.g. .svg, .png). If omitted, show the plot interactively.")
    parser.add_argument(
        "--dark-out", default=None,
        help="also render a dark-theme variant to this file")
    parser.add_argument(
        "--tables-out", default=None,
        help="write any accompanying data tables (pcap/seq/pgen) to this file "
        "as JSON")
    args = parser.parse_args(argv)

    if args.tables_out:
        with open(args.tables_out, "w") as f:
            json.dump(make_tables(args.path, args.section), f)

    if args.out:
        render(args.path, args.out, args.section, args.xlabel, dark=False)
        print(args.out)
        if args.dark_out:
            render(args.path, args.dark_out, args.section, args.xlabel,
                   dark=True)
            print(args.dark_out)
    elif not args.tables_out:
        make_timing_plot(args.path, args.section, args.xlabel)
        plt.show()
    return 0


if __name__ == "__main__":
    sys.exit(main())
