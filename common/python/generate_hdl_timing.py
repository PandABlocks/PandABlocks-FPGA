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
from .configs import BlockConfig
from .ini_util import read_ini, timing_entries

if TYPE_CHECKING:
    from typing import List

# Some paths
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")


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
            lstrip_blocks=True
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
            block = BlockConfig("BLOCK", 1, block_ini)
            for section in timing_ini.sections():
                if section != ".":
                    self.generate_timing_test(block, timing_ini, section, i)
                    i += 1

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
        values = dict(TS=0)
        for field in block.fields:
            header.append(field.name)
            # String becuase inputs and outputs from timing_entries are strings
            values[field.name] = "0"
        with open(os.path.join(timing_dir, "expected.csv"), "w") as f:
            # Write the header
            f.write("\t".join(header) + "\n")
            for ts, inputs, outputs in timing_entries(timing_ini, section):
                # If we jumped by more than one clock tick, put in another line
                # for the outputs
                if ts != values["TS"] + 1:
                    values["TS"] += 1
                    f.write("\t".join(str(values[k]) for k in header) + "\n")
                # For each timing entry provide the inputs
                values["TS"] = ts
                values.update(inputs)
                f.write("\t".join(str(values[k]) for k in header) + "\n")
                # Now update the values to be the outputs to output next clock
                # tick
                values.update(outputs)
        context = dict(section=section, block=block)
        self.expand_template("hdl_timing.v.jinja2", context, timing_dir,
                             "hdl_timing.v")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", help="Path to created hdl_timing dir")
    parser.add_argument("timings", metavar="T", nargs='+',
                        help="Timing ini files to create timing benches for")
    args = parser.parse_args()
    HdlTimingGenerator(args.build_dir, args.timings)


if __name__ == "__main__":
    main()
