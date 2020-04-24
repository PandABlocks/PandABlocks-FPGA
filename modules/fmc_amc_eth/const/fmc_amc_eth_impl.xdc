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

# -------------------------------------------------------------------
# FMC IO STANDARD
# -------------------------------------------------------------------
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[22]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[22]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[25]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[25]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[29]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[29]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[31]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[31]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[33]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[33]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[21]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[21]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[24]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[24]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[28]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[28]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[30]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[30]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[32]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[32]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[23]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[23]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[26]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[26]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[27]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[27]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[21]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[21]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[0]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[1]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[2]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[3]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[4]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[5]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[6]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[7]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[8]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[9]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[10]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[11]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[12]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[13]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[14]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[15]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[16]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[17]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[18]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[19]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[20]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[21]  ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[21]  ];
