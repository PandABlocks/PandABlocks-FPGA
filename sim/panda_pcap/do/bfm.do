vlib msim/xil_defaultlib
vlib msim/generic_baseblocks_v2_1
vlib msim/fifo_generator_v12_0
vlib msim/axi_data_fifo_v2_1
vlib msim/axi_infrastructure_v1_1
vlib msim/axi_register_slice_v2_1
vlib msim/axi_protocol_converter_v2_1

vmap xil_defaultlib msim/xil_defaultlib
vmap generic_baseblocks_v2_1 msim/generic_baseblocks_v2_1
vmap fifo_generator_v12_0 msim/fifo_generator_v12_0
vmap axi_data_fifo_v2_1 msim/axi_data_fifo_v2_1
vmap axi_infrastructure_v1_1 msim/axi_infrastructure_v1_1
vmap axi_register_slice_v2_1 msim/axi_register_slice_v2_1
vmap axi_protocol_converter_v2_1 msim/axi_protocol_converter_v2_1

vlog -64 -incr -work xil_defaultlib  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_wr.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_rd.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_wr_4.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_rd_4.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_hp2_3.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_arb_hp0_1.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_ssw_hp.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_sparse_mem.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_reg_map.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_ocm_mem.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_intr_wr_mem.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_intr_rd_mem.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_fmsw_gp.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_regc.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_ocmc.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_interconnect_model.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_gen_reset.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_gen_clock.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_ddrc.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_axi_slave.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_axi_master.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_afi_slave.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl/processing_system7_bfm_v2_0_processing_system7_bfm.v" \
"${MODEL}/zynq_ps.srcs/sources_1/bd/zynq_ps/ip/zynq_ps_ps_0/sim/zynq_ps_ps_0.v" \
"${MODEL}/zynq_ps.srcs/sources_1/bd/zynq_ps/ip/zynq_ps_hp1_0/hdl/src/verilog/zynq_ps_hp1_0.v" \

vlog -64 -incr -work generic_baseblocks_v2_1  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_carry_and.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_carry_latch_and.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_carry_latch_or.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_carry_or.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_carry.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_command_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_mask_static.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_mask.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_sel_mask_static.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_sel_mask.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_sel_static.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_sel.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator_static.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_comparator.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_mux_enc.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_mux.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/generic_baseblocks_v2_1/da89d453/hdl/verilog/generic_baseblocks_v2_1_nto1_mux.v" \

vcom -64 -93 -work fifo_generator_v12_0  \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/fifo_generator_v12_0/15467f24/simulation/fifo_generator_vhdl_beh.vhd" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/fifo_generator_v12_0/15467f24/hdl/fifo_generator_v12_0_vh_rfs.vhd" \

vlog -64 -incr -work axi_data_fifo_v2_1  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_axic_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_fifo_gen.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_axic_srl_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_axic_reg_srl_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_ndeep_srl.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_data_fifo_v2_1/82d298e6/hdl/verilog/axi_data_fifo_v2_1_axi_data_fifo.v" \

vlog -64 -incr -work axi_infrastructure_v1_1  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog/axi_infrastructure_v1_1_axi2vector.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog/axi_infrastructure_v1_1_axic_srl_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog/axi_infrastructure_v1_1_vector2axi.v" \

vlog -64 -incr -work axi_register_slice_v2_1  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_register_slice_v2_1/03a8e0ba/hdl/verilog/axi_register_slice_v2_1_axic_register_slice.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_register_slice_v2_1/03a8e0ba/hdl/verilog/axi_register_slice_v2_1_axi_register_slice.v" \

vlog -64 -incr -work axi_protocol_converter_v2_1  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_a_axi3_conv.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_axi3_conv.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_axilite_conv.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_r_axi3_conv.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_w_axi3_conv.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b_downsizer.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_decerr_slave.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_simple_fifo.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_wrap_cmd.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_incr_cmd.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_wr_cmd_fsm.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_rd_cmd_fsm.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_cmd_translator.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_b_channel.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_r_channel.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_aw_channel.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s_ar_channel.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_b2s.v" \
"${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_protocol_converter_v2_1/017861a2/hdl/verilog/axi_protocol_converter_v2_1_axi_protocol_converter.v" \

vlog -64 -incr -work xil_defaultlib  +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/processing_system7_bfm_v2_0/e69044ca/hdl +incdir+${MODEL}/zynq_ps.srcs/sources_1/ipshared/xilinx.com/axi_infrastructure_v1_1/cf21a66f/hdl/verilog \
"${MODEL}/zynq_ps.srcs/sources_1/bd/zynq_ps/ip/zynq_ps_auto_pc_0/sim/zynq_ps_auto_pc_0.v" \

vcom -64 -93 -work xil_defaultlib  \
"${MODEL}/zynq_ps.srcs/sources_1/bd/zynq_ps/hdl/zynq_ps.vhd" \

# compile glbl module
vlog -work xil_defaultlib "glbl.v"

