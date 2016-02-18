#!/bin/env dls-python
from pkg_resources import require
require("Jinja2")
import os
from jinja2 import Environment, FileSystemLoader
from  zebra2.configparser import ConfigParser
import collections

ROOT_DIR = os.path.abspath(os.pardir)
OUTPUT_DIR = os.path.join(ROOT_DIR, "build", "vhdl")
CONFIG_DIR = os.path.join(ROOT_DIR, "config_d")
PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_DIR = os.path.join(PATH, 'vhdl_templates')

template_environment = Environment(
    autoescape=False,
    loader=FileSystemLoader(TEMPLATE_DIR),
    trim_blocks=True)

def render_template(template_filename, context):
    return template_environment.get_template(template_filename).render(context)

def generateOutput(templatefile, outputfile, variables):
    fname = os.path.join(OUTPUT_DIR, outputfile)
    with open(fname, 'w') as f:
        output_file = render_template(templatefile, variables)
        f.write(output_file)

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    cfgParser = ConfigParser(CONFIG_DIR)

    #filter out the '*' charachter from the beginning of register names
    blocks = collections.OrderedDict()
    for blockname, block in cfgParser.blocks.items():
        blocks.update({blockname.replace("*", ""): block})
         #filter out the 'slow' keyword from those registers that have it
        for fieldname, field in block.fields.items():
            if field.reg[0] == 'slow':
                field.reg[0] = field.reg[1]
            #filter out register numbers after a "/"
            tempreg = []
            copy = True
            for num in field.reg:
                if num == "/": copy = False
                if copy : tempreg.append(num)
            field.reg = tempreg



    variables = {"blocks": blocks}
    generateOutput('addr_defines_template', "addr_defines.vhd", variables)
    generateOutput('addr_defines_template_verilog', "addr_defines.v", variables)
    generateOutput('panda_buses_template', "panda_busses.vhd", variables)

    for blockname, block in cfgParser.blocks.items():
        generateOutput('panda_block_ctrl_template', "panda_" + blockname.lower() + "_ctrl.vhd", {'block': block})


if __name__ == "__main__":
    main()
