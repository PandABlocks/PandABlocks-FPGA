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

#set_property LOC GTXE2_CHANNEL_X0Y3 \
#[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

#set_property LOC GTXE2_CHANNEL_X0Y2 \
#[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt1_sfpgtx_i/gtxe2_i]

#set_property LOC GTXE2_CHANNEL_X0Y1 \
#[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt2_sfpgtx_i/gtxe2_i]

#set_property LOC GTXE2_CHANNEL_X0Y2 [get_cells SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/core_support_i/*/*/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
#                                                             #core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i

############################################################
# GMII: IODELAY Constraints
############################################################
# Please modify the value of the IDELAY_VALUE
# according to your design.
# For more information on IDELAYCTRL and IODELAY, please
# refer to the Series-7 User Guide.
# apply the same IDELAY_VALUE to all GMII RX inputs
#set_property IDELAY_VALUE 30 [get_cells {SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/tri_mode_ethernet_mac_i/gmii_interface/delay_gmii_rx* tri_mode_ethernet_mac_i/gmii_interface/rxdata_bus[*].delay_gmii_rxd}]
# Group IODELAY components
#set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells {tri_mode_ethernet_mac_i/gmii_interface/delay_gmii_rx* tri_mode_ethernet_mac_i/gmii_interface/rxdata_bus[*].delay_gmii_rxd}]
#set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells  {tri_mode_ethernet_mac_idelayctrl_common_i}]
#[Common 17-55] 'set_property' expects at least one object. ["/home/eca/PandA/PandaFPGA/modules/sfp_udpontrig/const/sfp.xdc":44]

#[DRC 23-20] Rule violation (PLIDC-2) IDELAYCTRL DRC Checks - IDELAYCTRL elements have been found to be associated with IODELAY_GROUP 'eth_phy_i_iodelay_grp', but the design does not contain IODELAY elements associated with this IODELAY_GROUP.
#[DRC 23-20] Rule violation (PLIDC-2) IDELAYCTRL DRC Checks - IDELAYCTRL elements have been found to be associated with IODELAY_GROUP 'tri_mode_ethernet_mac_iodelay_grp', but the design does not contain IODELAY elements associated with this IODELAY_GROUP.

#set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells {SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_mac_i/U0/tri_mode_ethernet_mac_i/gmii_interface/delay_gmii_rx* SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_mac_i/U0/tri_mode_ethernet_mac_i/gmii_interface/rxdata_bus[*].delay_gmii_rxd}]
#set_property IODELAY_GROUP tri_mode_ethernet_mac_iodelay_grp [get_cells  SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_mac_i/U0/tri_mode_ethernet_mac_idelayctrl_common_i]
#set_property IODELAY_GROUP eth_phy_i_iodelay_grp [get_cells  {SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/delay_gmii_tx* SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/gmii_data_bus[*].delay_gmii_txd}]
#set_property IODELAY_GROUP eth_phy_i_iodelay_grp [get_cells  SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/core_idelayctrl_i]
#ERROR: [DRC 23-20] Rule violation (PLIDC-7) IDELAYCTRL DRC Checks - Design has more than one unlocked and ungrouped IDELAYCTRL instances. Please instantiate a delay controller (or use an existing one if delay values allow so) and apply appropriate IODELAY_GROUP or LOC constraints on the delay instances, or instantiate only one delay controller for the design without any IODELAY_GROUP or LOC constraints. The instances involved are:
#SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_mac_i/U0/tri_mode_ethernet_mac_idelayctrl_common_i
#SFP_GEN.sfp_inst/SFP_UDP_Complete_i2/eth_phy_i/core_idelayctrl_i
