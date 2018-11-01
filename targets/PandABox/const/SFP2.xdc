# -------------------------------------------------------------------
# SFP2 MGT - Bank 112
# -------------------------------------------------------------------

set_property PACKAGE_PIN AA9   [get_ports {SFP_RX_P[1]  }];   #SFP2_rx
set_property PACKAGE_PIN AB9   [get_ports {SFP_RX_N[1]  }];   #SFP2_rx
set_property PACKAGE_PIN AA5   [get_ports {SFP_TX_P[1]  }];   #SFP2_tx
set_property PACKAGE_PIN AB5   [get_ports {SFP_TX_N[1]  }];   #SFP2_tx

#set_property LOC GTXE2_CHANNEL_X0Y2 \
#[get_cells softblocks_inst/SFP_GEN.sfp2_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

