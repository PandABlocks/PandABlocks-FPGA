#!/bin/env dls-python
from pkg_resources import require
require("Jinja2")
import os
from jinja2 import Environment, FileSystemLoader
from  zebra2.configparser import ConfigParser

ROOT_DIR = os.path.abspath(os.pardir)
CONFIG_PATH = os.path.join(ROOT_DIR, "config_d")
PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(PATH, 'vhdl_templates')

template_environment = Environment(
    autoescape=False,
    loader=FileSystemLoader(TEMPLATE_PATH),
    trim_blocks=True)

def render_template(template_filename, context):
    return template_environment.get_template(template_filename).render(context)

def genearateOutput(templatefile, outputfile, variables):
    fname = os.path.join(TEMPLATE_PATH, outputfile)
    with open(fname, 'w') as f:
        output_file = render_template(templatefile, variables)
        f.write(output_file)

def main():
    cfgParser = ConfigParser(CONFIG_PATH)
    variables = {"blocks": cfgParser.blocks}

    genearateOutput('addr_defines_template', "addr_defines.vhd", variables)

if __name__ == "__main__":
    main()
