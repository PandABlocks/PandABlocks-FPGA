#!/bin/env dls-python
from pkg_resources import require
require("Jinja2")
import os, sys
import csv
import collections
from jinja2 import Environment, FileSystemLoader

ROOT_DIR = os.path.abspath(os.pardir)
OUTPUT_DIR = os.path.join(ROOT_DIR, "build", "config_d")
MODULE_DIR = os.path.join(ROOT_DIR, "modules")
APP_DIR = os.path.join(ROOT_DIR, "apps")

class ConfigGenerator(object):
    def __init__(self):
        self.template_environment = Environment(
            autoescape=False,
            loader=FileSystemLoader(MODULE_DIR),
            trim_blocks=True)

        self.template_environment.globals['newBitBus'] = self.newBitBus
        self.template_environment.globals['newBlockNo'] = self.newBlockNo
        self.template_environment.globals['newPosBus'] = self.newPosBus
        self.template_environment.globals['newBlockReg'] = self.newBlockReg
        self.app_config = collections.OrderedDict()
        self.current_bit_bus_value = 9
        self.current_pos_bus_value = 0
        self.current_block = 6
        self.block_regs = {}

    def render_template(self, template_filename, context):
        return self.template_environment.get_template(template_filename).render(context)

    def generateOutputFile(self, app_config, outputfile, variables):
        #generate the output config file
        fname = os.path.join(OUTPUT_DIR, outputfile)
        with open(fname, 'w') as f:
            #get the config templates from the panda_carrier and base
            output_file = self.render_template(os.path.join("base/", outputfile), variables)
            f.write(output_file)
            output_file = self.render_template(os.path.join("panda_carrier/", outputfile), variables)
            f.write(output_file)
            for config in app_config.keys():
                output_file = self.render_template(os.path.join(config.lower(), outputfile), variables)
                f.write(output_file)

    def generateDescription(self, app_config, outputfile):
        fname = os.path.join(OUTPUT_DIR, outputfile)
        with open(fname, 'w') as outfile:
            #get the description from the base
            description_file =  os.path.join(MODULE_DIR, "panda_carrier", "description")
            with open(description_file) as infile:
                outfile.write(infile.read())
            for config in app_config.keys():
                description_file = os.path.join(MODULE_DIR, config.lower(), "description")
                with open(description_file) as infile:
                    outfile.write(infile.read())

    def extractFileInfo(self, file):
        file_info = collections.OrderedDict()
        with open(file, 'rb') as csvfile:
            try:
                appreader = csv.reader(csvfile, delimiter=' ')
                for row in appreader:
                    #ignore comments and put in dictionary
                    if row and not row[0].startswith("#"):
                        file_info[row[0]] = row[1]
            except:
            #NEED SOME EXTRA CHECKING ON THIS FILE
                print "INVALID ENTRY, LINE", appreader.line_num,": ", row
        return file_info

    def parseAppFile(self, appfile):
        file = os.path.join(APP_DIR, appfile)
        self.app_config = self.extractFileInfo(file)
        self.initBlockRegs()
        return self.extractFileInfo(file)

    def initBlockRegs(self):
        for block in self.app_config.keys():
            self.block_regs[block] = -1

    def parseMetaFile(self, meta_file, block):
        meta_info = collections.OrderedDict()
        # meta_file = os.path.join(MODULE_DIR, block.lower(), "meta")
        try:
            meta_info = self.extractFileInfo(meta_file)
        except:
            print "no meta file for: ", block, sys.exc_info()[0]
        return meta_info

    def checkBlockMax(self, app_config):
        for block in app_config.keys():
            meta_file = os.path.join(MODULE_DIR, block.lower(), "meta")
            meta_info = self.parseMetaFile(meta_file, block)
            #check the defined number in the config against the max in the meta
            if int(app_config[block]) > int(meta_info["MAX"]):
                print block,app_config[block], "> MAX ", meta_info["MAX"]
                raise ValueError('Max value exceeded for ' + block)

    def newBitBus(self, block):
        bus_values = []
        for values in range(int(self.app_config[block.upper()])):
            if int(self.current_bit_bus_value) < 128:
                self.current_bit_bus_value += 1
                bus_values.append(str(self.current_bit_bus_value))
            else:
                raise ValueError('Max bit bus value exceeded')
        return " ".join(bus_values)

    def newPosBus(self, block):
        bus_values = []
        for values in range(int(self.app_config[block.upper()])):
            if int(self.current_pos_bus_value) < 64:
                self.current_pos_bus_value += 1
                bus_values.append(str(self.current_pos_bus_value))
            else:
                raise ValueError('Max pos bus value exceeded')
        return " ".join(bus_values)

    def newBlockNo(self):
        self.current_block += 1
        return str(self.current_block)

    def newBlockReg(self, block, type = '', offset=-1):
        if self.block_regs[block] < offset:
            self.block_regs[block] = offset
        if self.block_regs[block] < 64:
            self.block_regs[block] += 1
        else:
            raise ValueError('Max register value exceeded')
        out = str(self.block_regs[block])
        if 'bit_mux' in type:
            self.block_regs[block] += 1
            out += ' ' + str(self.block_regs[block])
        return out

if __name__ == '__main__':
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    cfg = ConfigGenerator()
    #read in app config file
    app_config = cfg.parseAppFile("myapp")
    variables = {"app_config": app_config}

    #-check that each requested config doesn't exceed the max (from the meta file)
    cfg.checkBlockMax(app_config)

    #combine all relevent descriptions for the output description file
    cfg.generateDescription(app_config, "description")

    #combine all relevent config for the output config file
    cfg.generateOutputFile(app_config, "config", variables)
        #-make sure to only include the ones that aren't 0
        #-other error checking ?

    #combine all relevent registers for the output registers file
    cfg.generateOutputFile(app_config, "registers", variables)
        #-check there are only unique bit numbers ?
        #-other error checking ?



