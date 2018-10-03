# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------
create_clock -period 8.000  [get_ports GTXCLK0_P]

set_property LOC GTXE2_CHANNEL_X0Y3 \
[get_cells SFP_GEN.sfp_inst1/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y2 \
[get_cells SFP_GEN.sfp_inst2/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt1_sfpgtx_i/gtxe2_i]

set_property LOC GTXE2_CHANNEL_X0Y1 \
[get_cells SFP_GEN.sfp_inst3/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt2_sfpgtx_i/gtxe2_i]
