#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'top_defines.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'operator.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'fifo.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'spbram.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'delay_line.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'bitmux.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'pcap_ctrl.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'panda_constants.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'reg_defines.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'addr_defines.vhd',
                   TOP_PATH / 'build' / 'apps' / 'PandABox-no-fmc' / 'autogen' / 'hdl' / 'top_defines_gen.vhd']

EXTRA_BUILD_ARGS = ['-Wno-hide']

TOP_LEVEL = 'pcap_core_wrapper'

EXTRA_SIGNALS_INFO = {
    'ARM': {'type': 'bit_mux', 'name': 'arm', 'wstb_name': 'arm'},
    'DISARM': {'type': 'bit_mux', 'name': 'disarm', 'wstb_name': 'disarm'},
    'START_WRITE': {'type': 'bit_mux', 'name': 'start_write',
                    'wstb_name': 'start_write'},
    'WRITE': {'type': 'bit_mux', 'name': 'write', 'wstb_name': 'write_wstb'},
    'POS': {'type': 'bus', 'name': 'pos_bus_i', 'bus_width': 26, 'bits': 32},
    'ACTIVE': {'type': 'bit_out', 'name': 'pcap_actv_o'},
    'DATA': {'type': 'monitor', 'name': 'dma_monitor'}
}
