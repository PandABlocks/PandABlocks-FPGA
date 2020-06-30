# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group s_axi_dcm_aclk0

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/support_layer_i/ethernet_core_i/U0/ten_gig_eth_pcs_pma/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK}]

#set_clock_groups -asynchronous -group [get_clocks \ 
#{softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i2/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK}]

#set_clock_groups -asynchronous -group [get_clocks \ 
#{softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i3/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK}]

#set_clock_groups -asynchronous -group [get_clocks \ 
#{softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i4/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# FMC MGTs - Bank 109
# -------------------------------------------------------------------

set_property LOC $FMC_HPC_GTX0_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/support_layer_i/ethernet_core_i/U0/ten_gig_eth_pcs_pma/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]

#set_property LOC $FMC_HPC_GTX1_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i2/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]

#set_property LOC $FMC_HPC_GTX2_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i3/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]

#set_property LOC $FMC_HPC_GTX3_LOC \
#[get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i4/fifo_block_i/support_layer_i/ethernet_core_i/U0/xpcs/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]


### from example design generation
##########################################################
#### Clock/period constraints                            #
##########################################################
#### Main transmit clock/period constraints
##
##create_clock -period 5.000 [get_ports clk_in]
##set_input_jitter clk_in 0.050
##create_clock -period 6,400 [get_ports refclk]
###
##########################################################
#### Synchronizer False paths
##########################################################
#ok to read in vivado 2015.2 but no need to meet timing
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/pattern_generator*sync1_r_reg[0]}]
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/reset_error_sync_reg*sync1_r_reg[0]}]
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/gen_enable_sync/sync1_r_reg[0]}]
#set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/*shared_clock_reset_block*sync1_r_reg[*]}] -filter {NAME =~ *PRE}]
#
########################################################
## FIFO level constraints
########################################################
#
#set_false_path -from [get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/ethernet_mac_fifo_i/*/wr_store_frame_tog_reg] -to [get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/ethernet_mac_fifo_i/*/*/sync1_r_reg*]
#set_max_delay 3.2000 -datapath_only  -from [get_cells {softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/ethernet_mac_fifo_i/*/rd_addr_gray_reg_reg[*]}] -to [get_cells softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/ethernet_mac_fifo_i/*/*/sync1_r_reg*]
#set_false_path -to [get_pins -filter {NAME =~ */PRE} -of_objects [get_cells {softblocks_inst/{{ block.name }}_inst/axi_10g_eth_example_design_i1/fifo_block_i/ethernet_mac_fifo_i/*/*/reset_async*_reg}]]
#
#########################################################
### I/O constraints                                     #
#########################################################
##
### These inputs can be connected to dip switches or push buttons on an
### appropriate board.
##
##set_false_path -from [get_ports reset]
##set_false_path -from [get_ports reset_error]
##set_false_path -from [get_ports insert_error]
##set_false_path -from [get_ports pcs_loopback]
##set_false_path -from [get_ports enable_pat_gen]
##set_false_path -from [get_ports enable_pat_check]
##set_false_path -from [get_ports enable_custom_preamble]
##set_case_analysis 0  [get_ports sim_speedup_control]
##
### These outputs can be connected to LED's or headers on an
### appropriate board.
##
##set_false_path -to [get_ports core_ready]
##set_false_path -to [get_ports coreclk_out]
##set_false_path -to [get_ports qplllock_out]
##set_false_path -to [get_ports frame_error]
##set_false_path -to [get_ports gen_active_flash]
##set_false_path -to [get_ports check_active_flash]
##set_false_path -to [get_ports serialized_stats]


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

