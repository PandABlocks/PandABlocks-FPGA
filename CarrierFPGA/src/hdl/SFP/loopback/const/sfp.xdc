# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------
set_property PACKAGE_PIN AB21   [get_ports {SFP_TxDis[0]  }];   #SFP1_IO1
set_property PACKAGE_PIN AB22   [get_ports {SFP_TxDis[1]  }];   #SFP2_IO1

set_property LOC GTXE2_CHANNEL_X0Y1 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y2 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt1_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y3 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt2_sfpgtx_i/gtxe2_i]


