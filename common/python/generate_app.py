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

import logging
import os

from argparse import ArgumentParser

from jinja2 import Environment, FileSystemLoader

from .compat import TYPE_CHECKING
from .configs import BlockConfig, pad, RegisterCounter, TargetSiteConfig
from .ini_util import read_ini, ini_get
import copy

if TYPE_CHECKING:
    from typing import List

log = logging.getLogger(__name__)

# Some paths
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
TEMPLATES = os.path.join(os.path.abspath(ROOT), "common", "templates")


# All options are disabled by default, this is also use to check allowed
# FPGA options, which could be enabled in the app ini file or in the target
# ini file
FPGA_OPTIONS_DEFAULTS = {
    'pcap_std_dev': False
}


def jinja_context(**kwargs):
    context = dict(pad=pad)
    context.update(kwargs)
    return context


def jinja_env(path):
    env = Environment(
        autoescape=False,
        loader=FileSystemLoader(path),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    return env


class AppGenerator(object):
    def __init__(self, app, app_build_dir):
        # type: (str, str) -> None
        # Make sure the outputs directory doesn't already exist
        assert not os.path.exists(app_build_dir), \
            "Output dir %r already exists" % app_build_dir
        self.app_build_dir = app_build_dir
        self.app_name = app.split('/')[-1].split('.')[0]
        # Create a Jinja2 environment in the templates dir
        self.env = jinja_env(TEMPLATES)
        # Start from base register 2 to allow for *REG and *DRV spaces
        self.counters = RegisterCounter(block_count = 2)
        # These will be created when we parse the ini files
        self.fpga_blocks = []  # type: List[BlockConfig]
        self.server_blocks = []  # type: List[BlockConfig]
        self.target_sites = [] #type: List[TargetSiteConfig]
        self.fpga_options = dict(FPGA_OPTIONS_DEFAULTS)  # type: dict[str, bool]
        self.app = app

    def generate_all(self):
        self.parse_ini_files(self.app)
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
        # First grab any includes
        initial_ini = read_ini(app)

        filenames = []
        for include in ini_get(initial_ini, ".", "includes", "").split():
            filenames.append(os.path.join(ROOT, "includes", include))
        filenames.append(app)

        # Load all the block definitions
        app_ini = read_ini(filenames)

        # The following code reads the target ini file for the specified target
        # The ini file declares the carrier blocks
        target = app_ini.get(".", "target")
        if target:
            # Implement the blocks for the target blocks
            target_ini = read_ini(os.path.join(ROOT, "targets", target, (
                    target + ".target.ini")))
            self.implement_blocks(target_ini, "modules", "carrier")
            # Read in what IO site options are available on target
            target_info = ini_get(target_ini,'.', 'io','').split('\n')
            for target in target_info:
                siteType, siteInfo = target.split(':')
                site=TargetSiteConfig(siteType, siteInfo)
                self.target_sites.append(site)
            # Read in which FPGA options are enabled on target
            self.process_fpga_options(
                ini_get(target_ini, '.', 'options', ''))

        # Process app specific FPGA options
        self.process_fpga_options(
            ini_get(app_ini, '.', 'options', ''))
        # Implement the blocks for the soft blocks
        self.implement_blocks(app_ini, "modules", "soft")
        # Filter option sensitive fields
        for block in self.server_blocks:
            to_delete = [
                field for field in block.fields
                    if not self.match_fpga_options(
                        self.parse_fpga_options(field.option_filter))
            ]
            for field in to_delete:
                block.fields.remove(field)

    def parse_fpga_options(self, text):
        # returns a dict with option -> expected_value
        options = {}
        for option in filter(None, (item.strip() for item in text.split(','))):
            expected = True
            if option.startswith('!'):
                option = option[1:].strip()
                expected = False

            assert option in self.fpga_options, \
                "%r option is not valid" % option

            options[option] = expected

        return options

    def match_fpga_options(self, options):
        for key, val in options.items():
            if self.fpga_options[key] != val:
                return False

        return True

    def implement_blocks(self, ini, path, type):
        """Read the ini file and for each section create a new block"""
        for section in ini.sections():
            if section != ".":
                module_name = ini_get(ini, section, 'module', section.lower())
                block_type = ini_get(ini, section, 'block', None)
                siteInfo = ini_get(ini, section, 'site', None)
                # If a site has been specified, is it valid?
                if siteInfo:
                    siteType=siteInfo.split(" ")[0]
                    siteNumber=int(siteInfo.split(" ")[1])
                    for site in self.target_sites:
                        if siteType in site.name:
                            target_sites = site.number
                    assert siteNumber in range(1, target_sites + 1), \
                        "Block %s in %s_site %s. Target only has %d sites" % (
                            section, siteType, siteNumber, target_sites)
                else:
                    siteNumber=None;

                if block_type:
                    ini_name = ini_get(
                        ini, section, 'ini', block_type + '.block.ini')
                else:
                    ini_name = ini_get(
                        ini, section, 'ini', module_name + '.block.ini')
                number = int(ini_get(ini, section, 'number', 1))

                ini_path = os.path.join(path, module_name, ini_name)
                # Type is soft if the block is a softblock and carrier
                # for carrier block
                block = BlockConfig(section, type, number, ini_path, siteNumber)
                block.register_addresses(self.counters)
                self.fpga_blocks.append(block)
                # Copy the fpga_blocks to the server blocks. Most blocks will
                # be the same between the two, however the block suffixes blocks
                # (they share a block address) need some differences.
                # Fpga_blocks will be used in fpga templates and server_blocks
                # will be used within the config blocks.
                if block.block_suffixes:
                    server_blocks = {}
                    # A new block is created for each of the block suffixes
                    for suffix in block.block_suffixes:
                        server_block = copy.deepcopy(block)
                        server_block.name = block.name + "_" + suffix
                        # There are no block_suffixes on the new server blocks
                        server_block.block_suffixes = []
                        # The block address is preceded with 'S' as it is shared
                        server_block.block_address = 'S%s' % block.block_address
                        # We will fill in the fields in the next step
                        server_block.fields = []
                        server_blocks[suffix] = server_block
                    # Distribute fields to the right blocks
                    for field in block.fields:
                        server_field = copy.deepcopy(field)
                        suffix, field_name = server_field.name.split(".")
                        server_field.name = field_name
                        server_blocks[suffix].fields.append(server_field)
                        # Change the source field name too
                        field.name = field.name.replace(".", "_")
                    # Add them to the server blocks list
                    for suffix in block.block_suffixes:
                        self.server_blocks.append(server_blocks[suffix])
                else:
                    # We need to copy because this is going to be filtered
                    # afterwards and we don't want to affect fpga_blocks
                    server_block = copy.deepcopy(block)
                    self.server_blocks.append(server_block)

    def expand_template(self, template_name, context, out_dir, out_fname,
                        template_dir=None):
        if template_dir:
            env = jinja_env(template_dir)
        else:
            env = self.env
        with open(os.path.join(out_dir, out_fname), "w") as f:
            template = env.get_template(template_name)
            f.write(template.render(context))

    def generate_config_dir(self):
        """Generate config, registers, descriptions in config_d"""
        config_dir = os.path.join(self.app_build_dir, "config_d")
        os.makedirs(config_dir)
        context = jinja_context(server_blocks=self.server_blocks,
                                app=self.app_name,
                                fpga_blocks=self.fpga_blocks)  # Create usage file
        vars = RegisterCounter.__dict__.copy()
        vars.update(self.counters.__dict__)
        usage = """####################################
# Resource usage
#  Block addresses: %(block_count)d/%(MAX_BLOCKS)d
#  Bit bus: %(bit_count)d/%(MAX_BIT)d
#  Pos bus: %(pos_count)d/%(MAX_POS)d
#  Ext bus: %(ext_count)d/%(MAX_EXT)d
####################################
""" % vars
        print(usage)
        with open(os.path.join(self.app_build_dir, "usage.txt"), "w") as f:
            f.write(usage)
        # Create the config, registers and descriptions files
        self.expand_template(
            "config.jinja2", context, config_dir, "config")
        self.expand_template(
            "registers.jinja2", context, config_dir, "registers")
        self.expand_template(
            "descriptions.jinja2", context, config_dir, "description")
        self.expand_template(
            "sim_server.jinja2", context, self.app_build_dir, "sim_server")

    def generate_wrappers(self):
        """Generate wrappers in hdl"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        os.makedirs(hdl_dir)
        # Create a wrapper for every block
        for block in self.fpga_blocks:
            context = jinja_context(fgpa_blocks=self.fpga_blocks)
            for k in dir(block):
                context[k] = getattr(block, k)
            if block.type in "soft|dma":
                self.expand_template("block_wrapper.vhd.jinja2", context,
                                     hdl_dir, "%s_wrapper.vhd" % block.entity)
            self.expand_template("block_ctrl.vhd.jinja2", context, hdl_dir,
                                 "%s_ctrl.vhd" % block.entity)

    def generate_soft_blocks(self):
        """Generate top hdl as well as the address defines"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        carrier_bit_bus_length = 0
        carrier_pos_bus_length = 0
        total_bit_bus_length = 0
        total_pos_bus_length = 0
        target_sites_num = 0
        # Start carrier_mod_count at 1 for REG and DRV blocks.
        carrier_mod_count = 2

        self.check_interfaces()

        for block in self.fpga_blocks:
            if block.type in "carrier|pcap":
                carrier_mod_count = carrier_mod_count + 1
            for field in block.fields:
                if block.type in "carrier|pcap":
                    if field.type == "bit_out":
                        carrier_bit_bus_length = carrier_bit_bus_length + block.number
                    if field.type == "pos_out":
                        carrier_pos_bus_length = carrier_pos_bus_length + block.number
                if field.type == "bit_out":
                    total_bit_bus_length = total_bit_bus_length + block.number
                if field.type == "pos_out":
                    total_pos_bus_length = total_pos_bus_length + block.number
        # total_pos_bus_length is zero the build will fail.
        if total_pos_bus_length == 0:
            total_pos_bus_length = 1
        block_names = []
        register_blocks = []
        # SFP blocks can have the same register definitions as they have
        # the same entity
        for block in self.fpga_blocks:
            if block.entity not in block_names:
                register_blocks.append(block)
                block_names.append(block.entity)

        context = jinja_context(
            fpga_blocks=self.fpga_blocks,
            target_sites=self.target_sites,
            fpga_options=self.fpga_options,
            carrier_bit_bus_length=carrier_bit_bus_length,
            carrier_pos_bus_length=carrier_pos_bus_length,
            total_bit_bus_length=total_bit_bus_length,
            total_pos_bus_length=total_pos_bus_length,
            carrier_mod_count=carrier_mod_count,
            register_blocks=register_blocks)
        self.expand_template("soft_blocks.vhd.jinja2", context, hdl_dir,
                             "soft_blocks.vhd")
        self.expand_template("addr_defines.vhd.jinja2", context, hdl_dir,
                             "addr_defines.vhd")
        self.expand_template("top_defines_gen.vhd.jinja2", context, hdl_dir,
                             "top_defines_gen.vhd")

    def check_interfaces(self):
        "If an interface is required in any blocks, is there a matching interface?"
        for block in self.fpga_blocks:
            for moduleInterface in block.interfaces:
                interfaceMatch = False
                for site in self.target_sites:
                    if moduleInterface[0] in site.interfaces:
                        interfaceMatch = True
                        target_sites_num = site.number
                assert interfaceMatch == True, "No %s interface on Carrier" % moduleInterface[0]
                if target_sites_num > 1:
                    assert block.site > 0,"No site defined for %s" % block.name

    def generate_constraints(self):
        """Generate constraints file for IPs, SFP and FMC constraints"""
        hdl_dir = os.path.join(self.app_build_dir, "hdl")
        const_dir = os.path.join(self.app_build_dir, "const")
        os.makedirs(const_dir)
        ips = []
        for block in self.fpga_blocks:
            for ip in block.ip:
                if ip not in ips:
                    ips.append(ip)
            for const in block.constraints:
                # Expand the constraints file
                context = jinja_context(block=block)
                out_fname = "%s_%s" % (block.name, os.path.basename(const))
                self.expand_template(
                    const, context, const_dir, out_fname, block.module_path)
        context = jinja_context(fpga_blocks=self.fpga_blocks, os=os, ips=ips)
        self.expand_template("constraints.tcl.jinja2", context, const_dir,
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
        context = jinja_context(regs=regs)
        self.expand_template("reg_defines.vhd.jinja2", context, hdl_dir,
                             "reg_defines.vhd")

    def hasnumbers(self, inputstring):
        # type: (str) -> bool
        """Simple check if string contains a number"""
        return any(char.isdigit() for char in inputstring)

    def process_fpga_options(self, options_text):
        self.fpga_options.update(self.parse_fpga_options(options_text))


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("build_dir", help="Path to created app dir")
    parser.add_argument("app", help="Path to app ini file")
    args = parser.parse_args()
    app = args.app
    build_dir = args.build_dir
    AppGenerator(app, build_dir).generate_all()


if __name__ == "__main__":
    main()
