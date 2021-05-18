# -------------------------------------------------------------------
# SFP MGTs - Bank 112
# -------------------------------------------------------------------

set_property LOC $SFP{{ block.site }}_GTX_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/core_support_i/pcs_pma_i/U0/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i]

#-----------------------------------------------------------
# GMII Tx Elastic Buffer Constraints                       -
#-----------------------------------------------------------

# Control Gray Code delay and skew across clock boundary
set_false_path -to [get_pins -hier -filter {name =~ softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/tx_elastic_buffer_inst/reclock_rd_addrgray*/data_sync*/D}]
set_false_path -to [get_pins -hier -filter {name =~ softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/tx_elastic_buffer_inst/reclock_wr_addrgray*/data_sync*/D}]

set_false_path -to [get_pins -hier -filter {name =~ softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/eth_phy_i/*/*reset_sync*/PRE }]
set_false_path -to [get_pins -hier -filter {name =~ softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/core_resets_i/pma_reset_pipe_reg*/PRE}]
set_false_path -to [get_pins -hier -filter {name =~ softblocks_inst/{{ block.name }}_inst/SFP_UDP_Complete_i/core_resets_i/pma_reset_pipe*[0]/D}]

