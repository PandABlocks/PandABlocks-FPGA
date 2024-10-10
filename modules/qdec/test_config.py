#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'qdec.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'qdecoder.vhd']

EXTRA_BUILD_ARGS = ['-fsynopsys']
