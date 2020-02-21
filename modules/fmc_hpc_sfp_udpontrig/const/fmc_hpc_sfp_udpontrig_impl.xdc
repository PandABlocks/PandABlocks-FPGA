# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group FMC_CLK0_M2C_P
set_clock_groups -asynchronous -group FMC_CLK1_M2C_P
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# FMC-SFP MGTs - Bank 109
# -------------------------------------------------------------------
set_property LOC $FMC_HPC_GTX0_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]

