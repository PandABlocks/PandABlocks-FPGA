# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.sfp_site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]
