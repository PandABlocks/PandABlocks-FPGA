# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.sfp_site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]

