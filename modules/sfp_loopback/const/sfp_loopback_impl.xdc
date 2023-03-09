# -------------------------------------------------------------------
# SFP Loopback MGT constraints
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i]


# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks \ 
{softblocks_inst/{{ block.name }}_inst/sfpgtx_exdes_i/sfpgtx_support_i/sfpgtx_init_i/U0/sfpgtx_i/gt0_sfpgtx_i/gtxe2_i/TXOUTCLK}]

