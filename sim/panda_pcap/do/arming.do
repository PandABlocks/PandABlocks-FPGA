vlib xil_defaultlib
vmap xil_defaultlib xil_defaultlib


vcom -64 -93 -work xil_defaultlib  \
"${SRC}/panda_pcap_arming.vhd" \

vlog -work xil_defaultlib "../bench/panda_pcap_arming_tb.v" \
"glbl.v"

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_pcap_arming_tb xil_defaultlib.glbl -o test_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib test_opt

add wave sim:/panda_pcap_arming_tb/*
add wave sim:/panda_pcap_arming_tb/uut/*

run 100us
