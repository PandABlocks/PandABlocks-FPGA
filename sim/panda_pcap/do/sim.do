set SRC {../../../src/hdl}
set BFM {../../../src/ip_repo/processing_system7_bfm_0}
set FIFO {../../../src/ip_repo/fifo_generator_0}

vlib work
vlib msim

vlib msim/fifo_generator_v12_0
vlib msim/xil_defaultlib

vmap fifo_generator_v12_0 msim/fifo_generator_v12_0
vmap xil_defaultlib msim/xil_defaultlib

vlog -64 -incr -work xil_defaultlib +incdir+${BFM}/hdl \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_wr.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_rd.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_wr_4.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_rd_4.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_hp2_3.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_arb_hp0_1.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_ssw_hp.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_sparse_mem.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_reg_map.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_ocm_mem.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_intr_wr_mem.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_intr_rd_mem.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_fmsw_gp.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_regc.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_ocmc.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_interconnect_model.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_gen_reset.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_gen_clock.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_ddrc.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_axi_slave.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_axi_master.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_afi_slave.v" \
"${BFM}/hdl/processing_system7_bfm_v2_0_processing_system7_bfm.v" \
"${BFM}/sim/processing_system7_bfm_0.v" \
"../bench/test.v" \

# compile glbl module
vlog -work xil_defaultlib "glbl.v"

# compile VHD
vcom -64 -93 -work fifo_generator_v12_0  \
"${FIFO}/fifo_generator_v12_0/simulation/fifo_generator_vhdl_beh.vhd" \
"${FIFO}/fifo_generator_v12_0/hdl/fifo_generator_v12_0_vh_rfs.vhd" \

vcom -64 -93 -work xil_defaultlib  \
"${FIFO}/sim/fifo_generator_0.vhd"\
"${SRC}/defines/type_defines.vhd" \
"${SRC}/defines/addr_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/panda_pcap.vhd" \
"../../panda_top/bench/test_interface.vhd" \
"../bench/panda_pcap_tb.vhd" \

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.test xil_defaultlib.glbl -o test_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib test_opt

add wave "sim:/test/tb/*"
add wave -group "S_AXI_HP0" "sim:/test/tb/zynq_ps/inst/S_AXI_HP0/*"



view wave

run 100us
