#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'top_defines.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'table_read_engine_client_transfer_manager.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'table_read_engine_client_length_manager.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'table_read_engine_client.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'spbram.vhd',
                   BUILD_PATH / 'apps' / 'pandabox-fmc-lback-sfp-lback' / 'autogen' / 'hdl' / 'top_defines_gen.vhd']
