vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -64 -93 -work xil_defaultlib  \
"${SRC}/defines/type_defines.vhd" \
"${SRC}/defines/addr_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/panda_pcap_dsp.vhd"

vlog -work xil_defaultlib "../bench/panda_pcap_dsp_tb.v" \
"glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_pcap_dsp_tb -o panda_pcap_dsp_tb_opt glbl

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib panda_pcap_dsp_tb_opt

view wave
configure wave -datasetprefix 0
configure wave -signalnamewidth 1

add wave -Radix Decimal "sim:/panda_pcap_dsp_tb/uut/*"
run -all
