# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------
create_clock -period 8.000  [get_ports GTXCLK0_P]

#create_clock -period 8.000  [get_ports softblocks_inst/SFP_GEN.sfp1_inst/sfpgtx_exdes_i/sfpgtx_support_i/q0_clk0_refclk_i] ##experimental!!

set_property PACKAGE_PIN W8   [get_ports {SFP_RX_P[0]  }];   #SFP1_rx
set_property PACKAGE_PIN Y8   [get_ports {SFP_RX_N[0]  }];   #SFP1_rx
set_property PACKAGE_PIN W4   [get_ports {SFP_TX_P[0]  }];   #SFP1_tx
set_property PACKAGE_PIN Y4   [get_ports {SFP_TX_N[0]  }];   #SFP1_tx

#set_property PACKAGE_PIN AA9   [get_ports {SFP_RX_P[1]  }];   #SFP2_rx
#set_property PACKAGE_PIN AB9   [get_ports {SFP_RX_N[1]  }];   #SFP2_rx
#set_property PACKAGE_PIN AA5   [get_ports {SFP_TX_P[1]  }];   #SFP2_tx
#set_property PACKAGE_PIN AB5   [get_ports {SFP_TX_N[1]  }];   #SFP2_tx

#set_property PACKAGE_PIN W6   [get_ports {SFP_RX_P[2]  }];   #SFP3_rx
#set_property PACKAGE_PIN Y6   [get_ports {SFP_RX_N[2]  }];   #SFP3_rx
#set_property PACKAGE_PIN W2   [get_ports {SFP_TX_P[2]  }];   #SFP3_tx
#set_property PACKAGE_PIN Y2   [get_ports {SFP_TX_N[2]  }];   #SFP3_tx
