#!/bin/env python
"""
Generate build/<app>/config_d from <app>.ini
"""
import os
import shutil
from argparse import ArgumentParser

from .compat import TYPE_CHECKING, configparser
from .configs import BlockConfig

if TYPE_CHECKING:
    from typing import List

# Some paths
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")

# Max number of Block types
# TODO: is this right?
MAX_BLOCKS = 64

# Max size of busses
MAX_BIT = 128
MAX_POS = 32
MAX_EXT = 32


def read_ini(path):
    # type: (str) -> configparser.SafeConfigParser
    app_ini = configparser.SafeConfigParser()
    assert app_ini.read(path), "Can't read ini file %s" % path
    return app_ini


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
        block_address = 2
        # The various busses
        bit_i, pos_i, ext_i = 0, 0, 0
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
                ini_path = os.path.join(ROOT, "modules", module_name, ini_name)
                block_ini = read_ini(ini_path)
                block = BlockConfig(section, number, block_ini)
                block_address, bit_i, pos_i, ext_i = block.register_addresses(
                    block_address, bit_i, pos_i, ext_i)
                assert block_address < MAX_BLOCKS, \
                    "Block %s overflowed %s Block types" % (
                        block.name, MAX_BLOCKS)
                assert bit_i < MAX_BIT, \
                    "Block %s overflowed %s bit bus entries" % (
                        block.name, MAX_BIT)
                assert pos_i < MAX_POS, \
                    "Block %s overflowed %s pos bus entries" % (
                        block.name, MAX_POS)
                assert ext_i < MAX_EXT, \
                    "Block %s overflowed %s ext bus entries" % (
                        block.name, MAX_EXT)
                self.blocks.append(block)

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
                for line in block.registers_lines():
                    f.write(line + "\n")
                f.write("\n")
        # Create the descriptions file
        with open(os.path.join(config_dir, "descriptions"), "w") as f:
            for block in self.blocks:
                for line in block.descriptions_lines():
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
