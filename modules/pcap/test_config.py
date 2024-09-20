#!/usr/bin/env python

EXTRA_HDL_FILES = [TOP_PATH / 'common' / 'hdl' / 'defines' / 'support.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'top_defines.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'defines' / 'operator.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'fifo.vhd',
                   TOP_PATH / 'common' / 'hdl' / 'spbram.vhd',
                   BUILD_PATH / 'apps' / 'PandABox-fmc_lback-sfp_lback' / 'autogen' / 'hdl' / 'top_defines_gen.vhd']

TOP_LEVEL = 'pcap_core_wrapper'

EXTRA_SIGNALS_INFO = {
    'ARM': {'type': 'bit_mux', 'name': 'arm', 'wstb_name': 'arm'},
    'DISARM': {'type': 'bit_mux', 'name': 'disarm', 'wstb_name': 'disarm'},
    'START_WRITE': {'type': 'bit_mux', 'name': 'start_write',
                    'wstb_name': 'start_write'},
    'WRITE': {'type': 'bit_mux', 'name': 'write', 'wstb_name': 'write_wstb'},
    'POS': {'type': 'bus', 'name': 'pos_bus_i', 'bits': 32, 'bus_width': 26},
    'ACTIVE': {'type': 'bit_out', 'name': 'pcap_actv_o'},
    'DATA': {'type': 'valid_data', 'name': 'pcap_dat_o',
             'valid_name': 'pcap_dat_valid_o'},
    'dma_full_i': {'type': 'bit_mux', 'name': 'dma_full_i'},
    'extbus_i': {'type': 'bus', 'name': 'extbus_i'},
    'BIT': {'type': 'bus', 'name': 'bit_bus_i', 'bits': 1, 'bus_width': 128}
}
