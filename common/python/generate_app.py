#!/bin/env dls-python
"""
Generate build/<app> from <app>.app.ini
"""
import os
import shutil
from argparse import ArgumentParser
from pkg_resources import require

require("jinja2")
from jinja2 import Environment, FileSystemLoader

from .compat import TYPE_CHECKING, configparser
from .configs import BlockConfig, pad
from .ini_util import read_ini

if TYPE_CHECKING:
    from typing import List

# Some paths
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")

# Max number of Block types
# TODO: is this right?
MAX_BLOCKS = 64

# Max size of buses
MAX_BIT = 128
MAX_POS = 32
MAX_EXT = 32


class AppGenerator(object):
    def __init__(self, app, app_build_dir):
        # type: (str, str) -> None
        # Make sure the outputs directory doesn't already exist
        assert not os.path.exists(app_build_dir), \
            "Output dir %r already exists" % app_build_dir
        self.app_build_dir = app_build_dir
        self.app_name = app.split('/')[-1].split('.')[0]
        # Create a Jinja2 environment in the templates dir
        self.env = Environment(
            autoescape=False,
            loader=FileSystemLoader(TEMPLATES),
            trim_blocks=True,
            lstrip_blocks=True,
            keep_trailing_newline=True,
        )
        # These will be created when we parse the ini files
        self.blocks = []  # type: List[BlockConfig]
        self.ip = []
        self.constraints = []
        self.sfpsites = []
        self.parse_ini_files(app)
        self.generate_config_dir()
        self.generate_wrappers()
        self.generate_soft_blocks()
        self.generate_constraints()
        self.generate_regdefs()

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
        # The following code reads the target ini file for the specified target
        # The ini file declares the carrier blocks
        target = app_ini.get(".", "target")
        if target:
            # Implement the blocks for the target blocks
            target_path = os.path.join(ROOT, "targets", target)
            target_ini = read_ini(os.path.join(target_path, (
                    target + ".target.ini")))
            block_address, bit_i, pos_i, ext_i = self.implement_blocks(
                target_ini, target_path, "carrier", "blocks",
                block_address, bit_i, pos_i, ext_i)
            try:
                self.constraints = target_ini.get(
                    ".", "sfp_constraints").split()
            except configparser.NoOptionError:
                self.constraints = ""
            try:
                self.sfpsites = target_ini.getint(".", "sfp_sites")
            except configparser.NoOptionError:
                self.sfpsites = 0
        # Implement the blocks for the soft blocks
        block_address, bit_i, pos_i, ext_i = self.implement_blocks(
            app_ini, ROOT, "soft", "modules",
            block_address, bit_i, pos_i, ext_i)
        print("####################################")
        print("# Resource usage")
        print("#  Block addresses: %d/%d" % (block_address, MAX_BLOCKS))
        print("#  Bit bus: %d/%d" % (bit_i, MAX_BIT))
        print("#  Pos bus: %d/%d" % (pos_i, MAX_POS))
        print("#  Ext bus: %d/%d" % (ext_i, MAX_EXT))
        print("####################################")
        assert block_address < MAX_BLOCKS, "Overflowed block addresses"
        assert bit_i < MAX_BIT, "Overflowed bit bus entries"
        assert pos_i < MAX_POS, "Overflowed pos bus entries"
        assert ext_i < MAX_EXT, "Overflowed ext bus entries"

    def implement_blocks(self, ini, path, type, subdir,
                         block_address,  bit_i, pos_i, ext_i):
        """Read the ini file and for each section create a new block"""
        for section in ini.sections():
            if section != ".":
                try:
                    module_name = ini.get(section, "module")
                except configparser.NoOptionError:
                    module_name = section.lower()

                try:
                    ini_name = ini.get(section, "ini")
                except configparser.NoOptionError:
                    ini_name = module_name + ".block.ini"
                try:
                    number = ini.getint(section, "number")
                except configparser.NoOptionError:
                    number = 1

                ini_path = os.path.join(path, subdir, module_name, ini_name)
                block_ini = read_ini(ini_path)
                # Type is soft if the block is a softblock and carrier
                # for carrier block
                block = BlockConfig(section, type, number, block_ini)
                block_address, bit_i, pos_i, ext_i = block.register_addresses(
                        block_address, bit_i, pos_i, ext_i)
                self.blocks.append(block)
        return block_address, bit_i, pos_i, ext_i

    def expand_template(self, template_name, context, out_dir, out_fname):
        with open(os.path.join(out_dir, out_fname), "w") as f:
            template = self.env.get_template(template_name)
            f.write(template.render(context))

    def generate_config_dir(self):
        """Generate config, registers, descriptions in config_d"""
        config_dir = os.path.join(self.app_build_dir, "config_d")
        os.makedirs(config_dir)
        context = dict(blocks=self.blocks, pad=pad)
        # Create the config, registers and descriptions files
        self.expand_template(
            "config.jinja2", context, config_dir, "config")
        self.expand_template(
            "registers.jinja2", context, config_dir, "registers")
        self.expand_template(
            "descriptions.jinja2", context, config_dir, "description")
        context = dict(app=self.app_name)
        self.expand_template(
            "slow_top.files.jinja2",
            context, self.app_build_dir, "slow_top.files")

    def generate_wrappers(self):
        """Generate wrappers in hdl"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        os.makedirs(hdl_dir)
        # Create a wrapper for every block
        for block in self.blocks:
            context = {k: getattr(block, k) for k in dir(block)}
            if block.type in "soft|dma":
                self.expand_template("block_wrapper.vhd.jinja2", context,
                                     hdl_dir, "%s_wrapper.vhd" % block.entity)
            self.expand_template("block_ctrl.vhd.jinja2", context, hdl_dir,
                                 "%s_ctrl.vhd" % block.entity)

    def generate_soft_blocks(self):
        """Generate top hdl as well as the address defines"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        bit_bus_length = 0
        pos_bus_length = 0
        for block in self.blocks:
            if block.type == "carrier":
                for field in block.fields:
                    if field.type == "bit_out":
                        bit_bus_length = bit_bus_length + block.number
                    if field.type == "pos_out":
                        pos_bus_length = pos_bus_length + block.number
        block_names = []
        register_blocks = []
        # SFP blocks can have the same register definitions as they have
        # the same entity
        for block in self.blocks:
            if block.entity not in block_names:
                register_blocks.append(block)
                block_names.append(block.entity)
        context = dict(blocks=self.blocks,
                       bit_bus_length=bit_bus_length,
                       pos_bus_length=pos_bus_length,
                       register_blocks=register_blocks)
        self.expand_template("soft_blocks.vhd.jinja2", context, hdl_dir,
                             "soft_blocks.vhd")
        self.expand_template("addr_defines.vhd.jinja2", context, hdl_dir,
                             "addr_defines.vhd")

    def generate_constraints(self):
        """Generate constraints file for IPs, SFP and FMC constraints"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        ips = []
        for block in self.blocks:
            for ip in block.ip:
                if ip not in ips:
                    ips.append(ip)
        context = dict(blocks=self.blocks,
                       sfpsites=self.sfpsites,
                       const=self.constraints,
                       ips=ips)
        self.expand_template("constraints.tcl.jinja2", context, hdl_dir,
                             "constraints.tcl")

    def generate_regdefs(self):
        """generate the registers define file from the registers server file"""
        reg_server_dir = os.path.join(
            ROOT, "common", "templates", "registers_server")
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        blocks = []
        data = []
        numbers = []
        regs = []
        with open(reg_server_dir, 'r') as fp:
            for line in fp:
                if "*" in line:
                    # The prefix for the signals are either REG or DRV
                    block = line.split(" ", 1)[0]
                if "#" not in line:
                    # Ignore any lines which are comments
                    # Reg name is the string before the last space
                    # Double space is used in case arrays are present
                    name = line.rsplit("  ", 1)[0].replace(" ", "")
                    # Number is string after last space
                    number = line.rsplit("  ", 1)[-1]
                    if ".." in number:
                        # Some of the values are arrays
                        [lownum, highnum] = number.split("..", 1)
                        lownum = [int(s) for s in lownum.split()
                                  if s.isdigit()][0]
                        highnum = [int(s) for s in highnum.split()
                                   if s.isdigit()][0]
                        for i in range((highnum + 1) - lownum):
                            array_name = name + "_" + str(i)
                            regs.append(dict(name=array_name,
                                             number=str(lownum + i),
                                             block=block.replace("*", "")))
                    else:
                        if self.hasnumbers(number):
                            # Avoids including blank lines
                            data.append(name)
                            numbers.append(number.replace("\n", ""))
                            blocks.append(block.replace("*", ""))
                            regs.append(dict(name=name,
                                             number=number.replace("\n", ""),
                                             block=block.replace("*", "")))
        context = dict(regs=regs)
        self.expand_template("reg_defines.vhd.jinja2", context, hdl_dir,
                             "reg_defines.vhd")

    def hasnumbers(self, inputstring):
        # type: (str) -> bool
        """Simple check if string contains a number"""
        return any(char.isdigit() for char in inputstring)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", help="Path to created app dir")
    parser.add_argument("app", help="Path to app ini file")
    args = parser.parse_args()
    app = args.app
    build_dir = args.build_dir
    AppGenerator(app, build_dir)


if __name__ == "__main__":
    main()
