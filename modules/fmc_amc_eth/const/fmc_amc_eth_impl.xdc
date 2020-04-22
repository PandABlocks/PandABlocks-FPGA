# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i2/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i2/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i3/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i3/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i4/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i4/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# FMC-SFP MGTs - Bank 109
# -------------------------------------------------------------------
set_property LOC $FMC_HPC_GTX0_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX1_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i2/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX2_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i3/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX3_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i4/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]

# -------------------------------------------------------------------
# AMC MGTs - Bank 112
# -------------------------------------------------------------------
#set_property LOC $AMC_P4_GTX_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
#set_property LOC $AMC_P5_GTX_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i2/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
#set_property LOC $AMC_P6_GTX_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i3/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
#set_property LOC $AMC_P7_GTX_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i4/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]

# -------------------------------------------------------------------
# AMC MGTs - Bank 111
# -------------------------------------------------------------------
set_property LOC $AMC_P8_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $AMC_P9_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i2/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $AMC_P10_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i3/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
set_property LOC $AMC_P11_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/eth_phy_to_phy_i4/eth_phy_i2/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]
