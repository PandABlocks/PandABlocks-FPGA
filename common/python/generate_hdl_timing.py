#!/bin/env dls-python
"""
Generate build/<app> from <app>.app.ini
"""
import os
from argparse import ArgumentParser
from pkg_resources import require

require("jinja2")
from jinja2 import Environment, FileSystemLoader
from .compat import TYPE_CHECKING, configparser
from .configs import BlockConfig, pad
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
        for i in self.header:
            # For any wstb signals set to '0'
            if "_wstb" in i:
                self.values[i] = str(0)

        for k, v in values.items():
            assert k in self.header, \
                "Field %r is not %s" % (k, self.header)
            # Lut Function values were given in hex, they need to be converted
            # to an int, for the testbench to pass
            if k != "TABLE_ADDRESS":
                v = str(int(v, 0))
            self.lengths[k] = max(self.lengths[k], len(v))
            self.values[k] = v
            # If the changes signal has a wstb, set wstb to '1'
            if k+"_wstb" in self.header:
                self.values[k + "_wstb"] = str(1)
        self.lines.append([self.values[k]for k in self.header])
        
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
            module_path = os.path.dirname(timing)
            block_ini = read_ini(os.path.join(module_path, block_ini_name))
            block = BlockConfig("BLOCK", "soft", 1, block_ini)
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
        for field in block.fields:
            if field.type == "time":
                header.append(field.name+"_L")
                header.append(field.name + "_H")
            elif field.type == "table short":
                header.append(field.name + "_START")
                header.append(field.name + "_DATA")
                header.append(field.name + "_LENGTH")
            elif field.type == "table":
                header.append(field.name + "_ADDRESS")
                header.append(field.name + "_LENGTH")
            else:
                header.append(field.name)
            # If field has wstb config, ass header for a wstb signal
            if field.wstb:
                if field.type == "time":
                    header.append(field.name + "_L_wstb")
                    header.append(field.name + "_H_wstb")
                elif field.type == "table short":
                    header.append(field.name + "_DATA_wstb")
                    header.append(field.name + "_LENGTH_wstb")
                elif field.type == "table":
                    header.append(field.name + "_ADDRESS_wstb")
                    header.append(field.name + "_LENGTH_wstb")
                else:
                    header.append(field.name + "_wstb")
        csv = TimingCsv(header)
        for_next_ts = {}  # type: Dict[str, str]
        for ts, inputs, outputs in timing_entries(timing_ini, section):
            # If we jumped by more than one clock tick, put in another line
            # for the outputs
            # Whenever an input is changed a new line is added on the next ts
            # which will reset any wstb signals to '0'. If there are no wstb
            # signals there will still be a new line but with no differences,
            # unless there are other changes to the input
            if for_next_ts and str(ts) == for_next_ts["TS"]:
                # Merge this with the inputs
                for_next_ts.update(inputs)
                csv.add_line(for_next_ts)
                # Add line in case of wstb signals
                for_next_ts = {"TS": str(ts + 1)}

            elif for_next_ts and inputs:
                # If input change at other TS, update outputs then inputs
                csv.add_line(for_next_ts)
                inputs["TS"] = str(ts)
                csv.add_line(inputs)
                # Add line in case of wstb signals
                for_next_ts = {"TS": str(ts + 1)}

            elif for_next_ts:
                # If no input change update outputs
                csv.add_line(for_next_ts)

            elif inputs:
                # For each timing entry provide the inputs
                inputs["TS"] = str(ts)
                csv.add_line(inputs)
                # In case of wstb signals, make a line for the next ts
                for_next_ts = {"TS": str(ts + 1)}

            # Now update the values to be the outputs to output next clock
            # tick
            if outputs:
                for_next_ts = {"TS": str(ts + 1)}
                for_next_ts.update(outputs)
            elif not inputs:
                for_next_ts = {}
        # Last line for outputs
        if for_next_ts:
            csv.add_line(for_next_ts)
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
            section=section,
            block=block,
            number=i,
            header=header,
            headerslength=headerslength,
        )

        self.expand_template("hdl_timing.v.jinja2", context, timing_dir,
                             "hdl_timing.v")

    # A script should be generated for each module for running the tests in
    # vivado. regression_tests.tcl searches through hdl_timing and finds every
    # tcl file, or if specified a chosen one, and runs it. single_test.tcl will
    # call a specific tcl file based on the inputted test.
    def generate_module_script(self, block, i):
        # type: (BlockConfig, int) -> None
        path = self.build_dir
        name = "%s.tcl" % block.entity
        context = dict(
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
