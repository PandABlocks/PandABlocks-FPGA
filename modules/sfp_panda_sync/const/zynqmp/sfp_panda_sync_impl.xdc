# -------------------------------------------------------------------
# SFP MGT constraint
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.site if block.site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_us_i/inst/gen_gtwizard_gthe4_top.sfp_panda_sync_us_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST]

# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins \
{softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_us_i/inst/gen_gtwizard_gthe4_top.sfp_panda_sync_us_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins \ 
{softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_us_i/inst/gen_gtwizard_gthe4_top.sfp_panda_sync_us_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins \ 
{softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_us_i/inst/gen_gtwizard_gthe4_top.sfp_panda_sync_us_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLKPCS}]]

