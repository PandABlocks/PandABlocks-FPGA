create_project sfp_top_module_tb ../../build/tests/sfp_top_module_tb -force -part xc7z030sbg485-1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -norecurse {../../common/vhdl/defines/support.vhd
../../common/vhdl/defines/top_defines.vhd
../../build/PandABox/autogen/addr_defines.vhd
../../modules/sfp_eventr/vhdl/sfp_event_receiver.vhd
../../modules/sfp_eventr/vhdl/sfp_receiver.vhd
../../modules/sfp_eventr/vhdl/sfp_transmitter.vhd
../../modules/sfp_eventr/vhdl/sfp_mmcm_clkmux.vhd
../../common/vhdl/delay_line.vhd
../../build/PandABox/autogen/sfp_ctrl.vhd
../../modules/sfp_eventr/vhdl/sfp_top.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt_gt.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt_cpll_railing.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt/example_design/event_receiver_mgt_sync_block.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt_multi_gt.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt/example_design/event_receiver_mgt_rx_startup_fsm.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt/example_design/event_receiver_mgt_tx_startup_fsm.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt_init.vhd
../../build/PandABox/ip_repo/event_receiver_mgt/event_receiver_mgt.vhd
../../build/PandABox/ip_repo/sfp_transmit_mem/sfp_transmit_mem_funcsim.vhdl
../../build/PandABox/ip_repo/ila_0/ila_0_funcsim.vhdl
../../tests/sim/sfp_receiver/bench/sfp_top_tb.vhd
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation
