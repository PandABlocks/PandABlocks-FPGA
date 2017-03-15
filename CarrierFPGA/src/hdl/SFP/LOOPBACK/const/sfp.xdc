# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------
create_clock -period 8.000  [get_ports GTXCLK0_P]

set_property PACKAGE_PIN W8   [get_ports {SFP_RX_P[2]  }];   #SFP3_rx !front SFP1
set_property PACKAGE_PIN Y8   [get_ports {SFP_RX_N[2]  }];   #SFP3_rx !front SFP1
set_property PACKAGE_PIN W4   [get_ports {SFP_TX_P[2]  }];   #SFP3_tx !front SFP1
set_property PACKAGE_PIN Y4   [get_ports {SFP_TX_N[2]  }];   #SFP3_tx !front SFP1

set_property PACKAGE_PIN AA9   [get_ports {SFP_RX_P[1]  }];   #SFP2_rx
set_property PACKAGE_PIN AB9   [get_ports {SFP_RX_N[1]  }];   #SFP2_rx
set_property PACKAGE_PIN AA5   [get_ports {SFP_TX_P[1]  }];   #SFP2_tx
set_property PACKAGE_PIN AB5   [get_ports {SFP_TX_N[1]  }];   #SFP2_tx

set_property PACKAGE_PIN W6   [get_ports {SFP_RX_P[0]  }];   #SFP1_rx !front SFP3
set_property PACKAGE_PIN Y6   [get_ports {SFP_RX_N[0]  }];   #SFP1_rx !front SFP3
set_property PACKAGE_PIN W2   [get_ports {SFP_TX_P[0]  }];   #SFP1_tx !front SFP3
set_property PACKAGE_PIN Y2   [get_ports {SFP_TX_N[0]  }];   #SFP1_tx !front SFP3

set_property LOC GTXE2_CHANNEL_X0Y3 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y2 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt1_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y1 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt2_sfpgtx_i/gtxe2_i]
