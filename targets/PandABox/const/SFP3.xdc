# -------------------------------------------------------------------
# SFP1 MGT - Bank 112
# -------------------------------------------------------------------

#set_property PACKAGE_PIN W8   [get_ports {SFP_RX_P[0]  }];   #SFP1_rx
#set_property PACKAGE_PIN Y8   [get_ports {SFP_RX_N[0]  }];   #SFP1_rx
#set_property PACKAGE_PIN W4   [get_ports {SFP_TX_P[0]  }];   #SFP1_tx
#set_property PACKAGE_PIN Y4   [get_ports {SFP_TX_N[0]  }];   #SFP1_tx

#set_property LOC GTXE2_CHANNEL_X0Y1 \
#[get_cells softblocks_inst/SFP_GEN.sfp3_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

