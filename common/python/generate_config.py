#!/bin/env python
"""
Generate build/<app>/config_d from <app>.ini
"""
import os
import shutil
from argparse import ArgumentParser

from .compat import TYPE_CHECKING, SafeConfigParser

if TYPE_CHECKING:
    from typing import Iterator


ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
CONFIG_D = os.path.join(os.path.abspath(ROOT), "build", "config_d")


def read_ini(path):
    # type: (str) -> SafeConfigParser
    app_ini = SafeConfigParser()
    assert app_ini.read(path), "Can't read ini file %s" % path
    return app_ini


class BlockConfig(object):

    # Max number of FPGA registers in a block
    MAX_REG = 64

    def __init__(self, block_name, module_name, ini_name, base, number):
        # type: (str, str, str, int) -> None
        self.block_name = block_name
        ini_path = os.path.join(ROOT, "modules", module_name, ini_name)
        self.block_ini = read_ini(ini_path)
        self.base = base  # base register address
        self.number = number  # number of blocks

    def description_lines(self):
        # type: () -> Iterator[str]
        """Produce the lines that will go in the description file"""
        # First line is the block name and desc
        description = self.block_ini.get(".", "desc")
        yield "%s\t%s" % (self.block_name, description)
        for section in self.block_ini.sections():
            if section != ".":
                # Every line after is a field name and desc
                section_desc = self.block_ini.get(section, "desc")
                yield "\t%s\t%s" % (section, section_desc)

    def config_lines(self):
        # type: () -> Iterator[str]
        """Produce the lines that will go in the config file"""
        # First line is the block name and number
        yield "%s[%s]" % (self.block_name, self.number)
        for section in self.block_ini.sections():
            if section != ".":
                section_type = self.block_ini.get(section, "type")
                # Some types have extra info
                split = section_type.split()
                assert len(split) in (1, 2), \
                    "Expected something like 'param enum', got %r" % split
                if len(split) == 1:
                    subtype = ""
                else:
                    subtype = split[1]
                yield "\t%s\t%s" % (section, "\t".join(split))
                if subtype == "enum":
                    # All the integer fields are enum values
                    for k, v in self.block_ini.items(section):
                        if k.isdigit():
                            yield "\t\t%s\t%s" % (k, v)

    def register_lines(self):
        # type: () -> Iterator[str]
        """Produce the lines that will go in the registers file"""
        # First line is the block name and number
        yield "%s\t%s" % (self.block_name, self.base)
        next_reg = 0
        for section in self.block_ini.sections():
            if section != ".":
                section_type = self.block_ini.get(section, "type")
                if section_type == "bit_mux":
                    nreg = 2
                else:
                    nreg = 1
                assert next_reg + nreg <= self.MAX_REG, \
                    "Block %s field %s exceeded %s registers" % (
                        self.block_name, section, self.MAX_REG)
                # Use some register numbers, incrementing self.next_reg so
                # we don't use them again
                regs = " ".join(str(next_reg + i) for i in range(nreg))
                next_reg += nreg
                yield "\t%s\t%s" % (section, regs)

    def bus_entries(self):
        """Produce the bit_bus and pos_bus entries"""
        pass


def generate_config_dir(app, config_dir):
    # type: (str, str) -> None
    # Remove the dir and make a new empty one
    if os.path.exists(config_dir):
        shutil.rmtree(config_dir)
    os.makedirs(config_dir)
    # Parse the ini files
    app_ini = read_ini(app)
    blocks = []
    # Load all the block definitions
    for section in app_ini.sections():
        if section != ".":
            try:
                module_name = app_ini.get(section, "module")
            except KeyError:
                module_name = section.lower()
            try:
                ini_name = app_ini.get(section, "ini")
            except KeyError:
                ini_name = section.lower() + "_block.ini"
            try:
                number = app_ini.getint(section, "number")
            except KeyError:
                number = 1
            blocks.append(BlockConfig(section, module_name, ini_name, number))
    # Create the files
    for fname in ("config", "registers", "description"):
        with open(os.path.join(config_dir, fname), "w") as f:
            for block in blocks:
                generator_func = getattr(block, "%s_lines" % fname)
                for line in generator_func():
                    f.write(line + "\n")
                f.write("\n")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("app", help="Path to app ini file")
    parser.add_argument("--config_dir", help="Path to build/config_d",
                        default=CONFIG_D)
    args = parser.parse_args()
    app = args.app
    config_dir = args.config_dir
    generate_config_dir(app, config_dir)


if __name__ == "__main__":
    main()