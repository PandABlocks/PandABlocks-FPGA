#!/usr/bin/env python
"""
Generate build/<app> from <app>.app.ini
"""
try:
    from pkg_resources import require
except ImportError:
    pass
else:
    require("jinja2")

import os
from argparse import ArgumentParser

from jinja2 import Environment, FileSystemLoader

from .compat import TYPE_CHECKING, configparser
from .configs import BlockConfig, pad, RegisterCounter
from .ini_util import read_ini, timing_entries

if TYPE_CHECKING:
    from typing import List, Dict

# Some paths
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")


class TimingCsv(object):
    def __init__(self, header):
        self.header = header
        # String because inputs and outputs from timing_entries are strings
        self.values = {k: "0" for k in header}
        self.lengths = {k: len(k) for k in header}
        self.lines = [header]

    def add_line(self, values):
        for_next_ts = {}
        for i in self.header:
            # For any wstb signals set to '0'
            if "_wstb" in i or "ARM" in i or "DISARM" in i or "START_WRITE" in i:
                self.values[i] = str(0)
        for k, v in values.items():
            assert k in self.header, \
                "Field %r is not %s" % (k, self.header)

            # Lut Function values were given in hex, they need to be
            # converted to an int, for the testbench to pass
            # Use bitmask operator to convert to 32-bit unsigned
            # as work-around for bug with $fscanf in Vivado2023.2
            v = str(int(v, 0) & 0xFFFFFFFF)

            self.lengths[k] = max(self.lengths[k], len(v))
            self.values[k] = v
            if "ARM" in k or "DISARM" in k or "START_WRITE" in k:
                self.values[k] = str(1)
            # If the changes signal has a wstb, set wstb to '1'
            if k+"_wstb" in self.header:
                self.values[k + "_wstb"] = str(1)
                for_next_ts["TS"] = str(int(self.values["TS"]) + 1)
        self.lines.append([self.values[k]for k in self.header])
        if for_next_ts:
            for_next_ts["TS"] = str(int(self.values["TS"]) + 1)
        return for_next_ts

    def write(self, f):
        for line in self.lines:
            padded = []
            for i, k in enumerate(self.header):
                padded.append(pad(line[i], self.lengths[k]))
            padded_str = " ".join(padded)
            f.write(padded_str.rstrip() + "\n")


class HdlTimingGenerator(object):
    def __init__(self, build_dir, timings):
        # type: (str, List[str]) -> None
        assert not os.path.exists(build_dir), \
            "Output dir %r already exists" % build_dir
        self.build_dir = build_dir
        self.timings = timings
        # Create a Jinja2 environment in the templates dir
        self.env = Environment(
            autoescape=False,
            loader=FileSystemLoader(TEMPLATES),
            trim_blocks=True,
            lstrip_blocks=True,
        )
        # Start making the timing templates
        i = 1
        for timing in self.timings:
            timing_ini = read_ini(timing)
            try:
                block_ini_name = timing_ini.get(".", "scope")
            except Exception:
                raise ValueError(
                    "Can't find section '.' with entry 'scope' in %s" % (
                        timing))
            ini_path = os.path.join(os.path.dirname(timing), block_ini_name)
            block = BlockConfig("BLOCK", "soft", 1, ini_path)
            block.register_addresses(RegisterCounter(block_count = 0))
            for section in timing_ini.sections():
                if section != ".":
                    self.generate_timing_test(block, timing_ini, section, i)
                    i += 1
            self.generate_module_script(block, i-1)

    def expand_template(self, template_name, context, out_dir, out_fname):
        with open(os.path.join(out_dir, out_fname), "w") as f:
            template = self.env.get_template(template_name)
            f.write(template.render(context))

    def generate_timing_test(self, block, timing_ini, section, i):
        # type: (BlockConfig, configparser.SafeConfigParser, str, int) -> None
        timing_dir = os.path.join(self.build_dir, "timing%03d" % i)
        os.makedirs(timing_dir)
        # Write the sequence values
        header = ["TS"]
        # PCAP is a special case
        if block.type == "pcap":
            header.append("START_WRITE")
            header.append("WRITE")
            header.append("WRITE_wstb")
            header.append("ARM")
            header.append("DISARM")
            header.append("DATA")
            header.append("DATA_wstb")
            for j in range(32):
                header.append("POS[" + str(j) + "]")
            for j in range(128):
                header.append("BIT[" + str(j) + "]")
        for field in block.fields:
            if "bit_mux" in field.type:
                header.append(field.name)
            else:
                for register in field.registers:
                    if register.number >= 0:
                        header.append(register.name)
                if field in block.filter_fields("bit.*|pos.*"):
                    for bus in field.bus_entries:
                        header.append(field.name)
            # If field has wstb config, ass header for a wstb signal
            if field.wstb:
                for register in field.registers:
                    if register.number >= 0:
                        header.append(register.name + "_wstb")
                for bus in field.bus_entries:
                    header.append(field.name)
        csv = TimingCsv(header)
        for_next_ts = {}  # type: Dict[str, str]
        for ts, inputs, outputs in timing_entries(timing_ini, section):
            # If we jumped by more than one clock tick, put in another line
            # for the outputs
            # Whenever an input is changed a new line is added on the next ts
            # which will reset any wstb signals to '0'. If there are no wstb
            # signals there will still be a new line but with no differences,
            # unless there are other changes to the input
            if for_next_ts:
                # First handle outputs from last ts, then any changing wstbs
                for _ in range(2):
                    # Check if we can insert this before the next ts
                    if for_next_ts and for_next_ts["TS"] != str(ts):
                        # If there were write strobes that need resetting before
                        # this line then do so
                        for_next_ts = csv.add_line(for_next_ts)
            # Now we should either have something with the same ts, or
            # it should be blank
            if for_next_ts:
                assert str(ts) == for_next_ts["TS"], \
                    "Expected %s to have ts %s" % (for_next_ts, ts)
                inputs.update(for_next_ts)
                for_next_ts = {}
            # Handle inputs
            if inputs:
                # For each timing entry provide the inputs
                inputs["TS"] = str(ts)
                for_next_ts = csv.add_line(inputs)
            # Now update the values to be the outputs to output next clock
            # tick
            if outputs:
                for_next_ts["TS"] = str(ts + 1)
                for_next_ts.update(outputs)
        # First handle outputs from last ts, then any changing wstbs
        for _ in range(2):
            # Check if we can insert this before the next ts
            if for_next_ts:
                # If there were write strobes that need resetting before
                # this line then do so
                for_next_ts = csv.add_line(for_next_ts)
        assert not for_next_ts, "Why do we still have %s?" % str(for_next_ts)
        # File name needs to be unique to the test
        expected_csv = "%d%sexpected.csv" % (i, block.entity)
        with open(os.path.join(timing_dir, expected_csv), "w") as f:
            csv.write(f)
        # A temporary array for reading the header line is used in testbench
        # The length of header line is passed into the template
        with open(os.path.join(timing_dir, expected_csv)) as f:
            first_line = f.readline()
        headerslength = len(first_line) - 1
        context = dict(
            pad=pad,
            section=section,
            block=block,
            number=i,
            header=header,
            headerslength=headerslength,
        )
        if block.type == "pcap":
            self.expand_template("pcap_hdl_timing.sv.jinja2", context,
                                 timing_dir, "hdl_timing.sv")
        else:
            self.expand_template("hdl_timing.sv.jinja2", context, timing_dir,
                                 "hdl_timing.sv")

    # A script should be generated for each module for running the tests in
    # vivado. regression_tests.tcl searches through hdl_timing and finds every
    # tcl file, or if specified a chosen one, and runs it. single_test.tcl will
    # call a specific tcl file based on the inputted test.
    def generate_module_script(self, block, i):
        # type: (BlockConfig, int) -> None
        path = self.build_dir
        name = "%s.tcl" % block.entity
        context = dict(
            pad=pad,
            block=block,
            number=i,
        )
        self.expand_template("module.tcl.jinja2", context, path, name)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", help="Path to created hdl_timing dir")
    parser.add_argument("timings", metavar="T", nargs='+',
                        help="Timing ini files to create timing benches for")
    args = parser.parse_args()
    HdlTimingGenerator(args.build_dir, args.timings)


if __name__ == "__main__":
    main()
