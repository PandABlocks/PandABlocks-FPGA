#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'top_defines.vhd',
                   BUILD_PATH / 'apps' / 'pandabox-fmc-lback-sfp-lback' / 'autogen' / 'hdl' / 'top_defines_gen.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'fifo.vhd']
