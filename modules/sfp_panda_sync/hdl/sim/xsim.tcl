#open_wave_config {/scratch/clm61942/PandA_tmp/fmc_panda_sync/sync-fix/PandABlocks-FPGA/modules/sfp_panda_sync/hdl/sim/build/work.pandaSync_tx_TB_work.glbl.wcfg}
#add_force /pandaSync_tx_TB/uut/wren_low 1 496 -cancel_after 696
#add_force /pandaSync_tx_TB/uut/rden_low 1 896 -cancel_after 1096
add_force /pandaSync_rx_TB/uut/rx_link_ok 1 100
run all

