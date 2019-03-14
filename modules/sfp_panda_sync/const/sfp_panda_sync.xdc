# -------------------------------------------------------------------
# SFP MGT constraint
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.sfp_site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_i/U0/sfp_panda_sync_i/gt0_sfp_panda_sync_i/gtxe2_i]

# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
#set_clock_groups -asynchronous -group [get_clocks \ 
#{softblocks_inst/{{ block.name }}_inst/sfpgtx_event_receiver_inst/event_receiver_mgt_inst/U0/event_receiver_mgt_i/gt0_event_receiver_mgt_i/gtxe2_i/RXOUTCLK}]

