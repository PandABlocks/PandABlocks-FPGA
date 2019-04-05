# -------------------------------------------------------------------
# SFP MGT constraint
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.sfp_site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfp_panda_sync_mgt_interface_inst/sfp_panda_sync_i/U0/sfp_panda_sync_i/gt0_sfp_panda_sync_i/gtxe2_i]

