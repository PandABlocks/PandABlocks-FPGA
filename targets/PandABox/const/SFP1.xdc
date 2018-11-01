# -------------------------------------------------------------------
# SFP3 MGT - Bank 112
# -------------------------------------------------------------------

set_property PACKAGE_PIN W6   [get_ports {SFP_RX_P[2]  }];   #SFP3_rx
set_property PACKAGE_PIN Y6   [get_ports {SFP_RX_N[2]  }];   #SFP3_rx
set_property PACKAGE_PIN W2   [get_ports {SFP_TX_P[2]  }];   #SFP3_tx
set_property PACKAGE_PIN Y2   [get_ports {SFP_TX_N[2]  }];   #SFP3_tx

#set_property LOC GTXE2_CHANNEL_X0Y3 \
#[get_cells softblocks_inst/SFP_GEN.sfp1_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

