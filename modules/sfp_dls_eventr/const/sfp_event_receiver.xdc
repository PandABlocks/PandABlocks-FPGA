# -------------------------------------------------------------------
# SFP MGTs - X0Y1
# -------------------------------------------------------------------

#create_clock -period 8.000  [get_ports GTXCLK0_P]

set_property LOC $SFP3_GTX_LOC \
[get_cells softblocks_inst/SFP_GEN.sfp3_inst/sfpgtx_event_receiver_inst/event_receiver_mgt_inst/U0/event_receiver_mgt_i/gt0_event_receiver_mgt_i/gtxe2_i]
