file delete -force read_from_hp1.txt

set SRC {../../../src/hdl}
set IP {../../../output/ip_repo}
set MODEL {../../panda_top/bench/zynq_model}

vlib work
vlib msim

#do bfm.do

#
# Compile Testbench
#
vlog -work xil_defaultlib "../bench/test.v" \
"glbl.v"

vcom -64 -93 -work xil_defaultlib  \
"${IP}/pcap_dma_fifo/sim/pcap_dma_fifo.vhd"\
"${IP}/pulse_queue/sim/pulse_queue.vhd"\
"${SRC}/defines/type_defines.vhd" \
"${SRC}/defines/addr_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/panda_axi3_write_master.vhd" \
"${SRC}/panda_spbram.vhd" \
"${SRC}/panda_csr_if.vhd" \
"${SRC}/panda_pcap_ctrl.vhd" \
"${SRC}/panda_pcap_buffer.vhd" \
"${SRC}/panda_pcap_posproc.vhd" \
"${SRC}/panda_pcap_frame.vhd" \
"${SRC}/panda_pcap_arming.vhd" \
"${SRC}/panda_pcap_dma.vhd" \
"${SRC}/panda_pcap_core.vhd" \
"${SRC}/panda_pcap_top.vhd" \
"../../panda_top/bench/test_interface.vhd" \
"../bench/panda_pcap_tb.vhd" \

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -L generic_baseblocks_v2_1 -L fifo_generator_v12_0 -L axi_data_fifo_v2_1 -L axi_infrastructure_v1_1 -L axi_register_slice_v2_1 -L axi_protocol_converter_v2_1 -work xil_defaultlib xil_defaultlib.test xil_defaultlib.glbl -o test_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib test_opt

add wave -group "TOP" sim:/test/tb/uut/*
add wave -group "DMA" sim:/test/tb/uut/pcap_dma_inst/*



run -all
