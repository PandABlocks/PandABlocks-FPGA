# -------------------------------------------------------------------
# SFP MGT constraint
# -------------------------------------------------------------------

set_property LOC ${{block.site_LOC}}_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_i/U0/sfp_panda_sync_i/gt0_sfp_panda_sync_i/gtxe2_i]

# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks \ 
{softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_i/U0/sfp_panda_sync_i/gt0_sfp_panda_sync_i/gtxe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks \ 
{softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_i/U0/sfp_panda_sync_i/gt0_sfp_panda_sync_i/gtxe2_i/RXOUTCLK}]

