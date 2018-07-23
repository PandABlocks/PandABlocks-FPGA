#!/bin/env python
"""
Generate build/<app>/config_d from <app>.ini
"""
import os
import shutil
from argparse import ArgumentParser

from .compat import TYPE_CHECKING, configparser

if TYPE_CHECKING:
    from typing import Iterator, List, Dict

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")


def read_ini(path):
    # type: (str) -> configparser.SafeConfigParser
    app_ini = configparser.SafeConfigParser()
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

    def register_lines(self, busses):
        # type: () -> Iterator[str]
        """Produce the lines that will go in the registers file, adding
        _out entries to the relevant busses"""
        # First line is the block name and number
        yield "%s\t%s" % (self.block_name, self.base)
        next_reg = 0
        for section in self.block_ini.sections():
            if section != ".":
                section_type = self.block_ini.get(section, "type")
                if section_type in ("bit_out", "pos_out", "ext_out"):
                    regs = []
                    for i in range(self.number):
                        if self.number == 1:
                            # Squash suffix for only one block
                            name = "%s.%s" % (self.block_name, section)
                        else:
                            name = "%s%s.%s" % (self.block_name, i+1, section)
                        bus = busses[section_type[:3] + "_bus"]
                        regs.append(len(bus))
                        bus.append(name)
                else:
                    if section_type == "bit_mux":
                        nreg = 2
                    else:
                        nreg = 1
                    assert next_reg + nreg <= self.MAX_REG, \
                        "Block %s field %s exceeded %s registers" % (
                            self.block_name, section, self.MAX_REG)
                    # Use some register numbers, incrementing self.next_reg so
                    # we don't use them again
                    regs = [next_reg + i for i in range(nreg)]
                    next_reg += nreg
                yield "\t%s\t%s" % (section, " ".join(str(r) for r in regs))


class AppGenerator(object):
    def __init__(self, app, app_build_dir):
        # type: (str, str) -> None
        # Remove the dir and make a new empty one
        if os.path.exists(app_build_dir):
            shutil.rmtree(app_build_dir)
        self.app_build_dir = app_build_dir
        # These will be created when we parse the ini files
        self.blocks = []  # type: List[BlockConfig]
        self.parse_ini_files(app)
        # These will be filled in when the register lines are generated
        self.busses = dict(
            bit_bus=[], pos_bus=[], ext_bus=[])  # type: Dict[str, List[str]]
        self.generate_config_dir()

    def parse_ini_files(self, app):
        # type: (str) -> None
        """Parse the app and all the block ini files it refers to, creating
        busses

        Args:
            app: Path to the top level app ini file

        Returns:
            The names of the signals on the bit, pos, and ext_out busses
        """
        app_ini = read_ini(app)
        # Load all the block definitions
        # Start from base register 2 to allow for *REG and *DRV spaces
        base = 2
        for section in app_ini.sections():
            if section != ".":
                try:
                    module_name = app_ini.get(section, "module")
                except configparser.NoOptionError:
                    module_name = section.lower()
                try:
                    ini_name = app_ini.get(section, "ini")
                except configparser.NoOptionError:
                    ini_name = section.lower() + "_block.ini"
                try:
                    number = app_ini.getint(section, "number")
                except configparser.NoOptionError:
                    number = 1
                self.blocks.append(BlockConfig(
                    section, module_name, ini_name, base, number))
                base += 1

    def generate_config_dir(self):
        config_dir = os.path.join(self.app_build_dir, "config_d")
        os.makedirs(config_dir)
        # Create the config file
        with open(os.path.join(config_dir, "config"), "w") as f:
            # Write the header
            with open(os.path.join(TEMPLATES, "config_header")) as src:
                f.write(src.read())
            for block in self.blocks:
                for line in block.config_lines():
                    f.write(line + "\n")
                f.write("\n")
        # Create the registers file
        with open(os.path.join(config_dir, "registers"), "w") as f:
            # Write the header
            with open(os.path.join(TEMPLATES, "registers_header")) as src:
                f.write(src.read())
            for block in self.blocks:
                for line in block.register_lines(self.busses):
                    f.write(line + "\n")
                f.write("\n")
        # Create the descriptions file
        with open(os.path.join(config_dir, "descriptions"), "w") as f:
            for block in self.blocks:
                for line in block.description_lines():
                    f.write(line + "\n")
                f.write("\n")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("app", help="Path to app ini file")
    parser.add_argument("app_build_dir", help="Path to created app dir")
    args = parser.parse_args()
    app = args.app
    app_build_dir = args.app_build_dir
    AppGenerator(app, app_build_dir)


if __name__ == "__main__":
    main()
