# -------------------------------------------------------------------
# SFP MGTs - X0Y1
# -------------------------------------------------------------------

create_clock -period 8.000  [get_ports GTXCLK0_P]

set_property LOC GTXE2_CHANNEL_X0Y1 \
[get_cells SFP_GEN.sfp_inst/sfpgtx_event_receiver_inst/event_receiver_mgt_inst/U0/event_receiver_mgt_i/gt0_event_receiver_mgt_i/gtxe2_i]
