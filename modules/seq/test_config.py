#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'top_defines.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'spbram.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'top_defines_gen.vhd']

# EXTRA_BUILD_ARGS = ['-frelaxed']
# Use -frelaxed when simulating shared variables. Turns an error into a warning.

