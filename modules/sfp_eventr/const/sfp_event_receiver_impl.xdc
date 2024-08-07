# -------------------------------------------------------------------
# SFP MGT constraint
# -------------------------------------------------------------------

set_property LOC ${{ block.site_LOC }}_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfpgtx_event_receiver_inst/event_receiver_mgt_inst/U0/event_receiver_mgt_i/gt0_event_receiver_mgt_i/gtxe2_i]

# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks \ 
{softblocks_inst/{{ block.name }}_inst/sfpgtx_event_receiver_inst/event_receiver_mgt_inst/U0/event_receiver_mgt_i/gt0_event_receiver_mgt_i/gtxe2_i/RXOUTCLK}]

