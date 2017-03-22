#!/bin/env dls-python
from pkg_resources import require
require("Jinja2")
import os, sys
import getopt
from jinja2 import Environment, FileSystemLoader
from  common.python.pandablocks.configparser import ConfigParser
import collections

ROOT_DIR = os.path.abspath(os.pardir)
# OUTPUT_DIR = os.path.join(ROOT_DIR, "build/PandABox", "autogen")
# CONFIG_DIR = os.path.join(ROOT_DIR, "build/config_d")
PAR_DIR = os.path.join(__file__, os.pardir, os.pardir)
ROOT_DIR = os.path.dirname(os.path.abspath(PAR_DIR))
PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_DIR = os.path.join(PATH, 'vhdl_templates')

class VhdlGenerator(object):
    def __init__(self, output_dir):
        self.template_environment = Environment(
            autoescape=False,
            loader=FileSystemLoader(TEMPLATE_DIR),
            trim_blocks=True,
            extensions=["jinja2.ext.do",])
        self.output_dir = os.path.join(ROOT_DIR, output_dir, "autogen")
        self.config_dir = os.path.join(ROOT_DIR, output_dir, "config_d")
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        self.cfgParser = ConfigParser(self.config_dir)

    def render_template(self, template_filename, context):
        return self.template_environment.get_template(template_filename).render(context)

    def generateOutput(self, templatefile, outputfile, variables):
        fname = os.path.join(self.output_dir, outputfile)
        with open(fname, 'w') as f:
            output_file = self.render_template(templatefile, variables)
            f.write(output_file)

def main(argv):
    output_dir = "build"
    try:
        opts, args = getopt.getopt(argv, "ho:", ["outputdir="])
    except getopt.GetoptError:
        print 'vhdl_generator.py -o <output dir>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'vhdl_generator.py -o <output dir>'
            sys.exit(2)
        elif opt in ("-o", "--outputdir"):
            output_dir = arg

    vhdl_gen = VhdlGenerator(output_dir)

    #filter out the '*' charachter from the beginning of block names
    blocks = collections.OrderedDict()
    for blockname, block in vhdl_gen.cfgParser.blocks.items():
        blocks.update({blockname.replace("*", ""): block})
         #filter out the 'slow' keyword from those registers that have it
        for fieldname, field in block.fields.items():
            if field.reg[0] == 'slow':
                field.reg[0] = field.reg[1]
            #filter out register numbers after a "/" whithout copying "/"
            tempreg = []
            copy = True
            for num in field.reg:
                if num == "/":
                    copy = False
                    continue
                if copy : tempreg.append(num)
            field.reg = tempreg

    variables = {"blocks": blocks}
    vhdl_gen.generateOutput('addr_defines_template', "addr_defines.vhd", variables)
    vhdl_gen.generateOutput('addr_defines_template_verilog', "addr_defines.v", variables)
    vhdl_gen.generateOutput('panda_buses_template', "panda_busses.vhd", variables)
    vhdl_gen.generateOutput('panda_bitbus_template', "panda_bitbus.v", variables)

    for blockname, block in vhdl_gen.cfgParser.blocks.items():
        if not blockname.startswith('*'):
            vhdl_gen.generateOutput('panda_block_ctrl_template',
                           blockname.lower() + "_ctrl.vhd",
                           {'block': block})

if __name__ == '__main__':
    main(sys.argv[1:])
