# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------

set_property LOC $SFP1_GTX_LOC \
[get_cells softblocks_inst/SFP_GEN.sfp1_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]


# Site: {{ block.sfp_site }}

# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks -filter {NAME =~ softblocks_inst/SFP_GEN.sfp1_inst/*TXOUTCLK}]

