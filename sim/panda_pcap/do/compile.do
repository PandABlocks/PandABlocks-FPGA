vlib work
vlib msim

vlib msim/fifo_generator_v12_0
vlib msim/xil_defaultlib

vmap fifo_generator_v12_0 msim/fifo_generator_v12_0
vmap xil_defaultlib msim/xil_defaultlib

set SRC {../../../src/hdl}
set IP {../../../output/ip_repo/pcap_dma_fifo}

vcom -64 -93 -work fifo_generator_v12_0  \
"${IP}/fifo_generator_v12_0/simulation/fifo_generator_vhdl_beh.vhd" \
"${IP}/fifo_generator_v12_0/hdl/fifo_generator_v12_0_vh_rfs.vhd" \

vcom -64 -93 -work xil_defaultlib  \
"${IP}/sim/pcap_dma_fifo.vhd"\
"${SRC}/autogen/addr_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/defines/panda_version.vhd" \
"${SRC}/spbram.vhd" \
"${SRC}/axi_write_master.vhd" \
"${SRC}/pcap_posproc.vhd" \
"${SRC}/pcap_frame.vhd" \
"${SRC}/pcap_arming.vhd" \
"${SRC}/pcap_buffer.vhd" \
"${SRC}/pcap_core.vhd" \
"../bench/pcap_core_wrapper.vhd" \


vlog -work xil_defaultlib   \
"../bench/pcap_core_tb.v"   \
"/dls_sw/FPGA/Xilinx/14.7/ISE_DS/ISE/verilog/src/glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.pcap_core_tb -o pcap_core_opt glbl

vsim -t 1ps -voptargs=+acc -lib xil_defaultlib pcap_core_opt

view wave


add wave -noupdate -radix decimal /pcap_core_tb/ACTIVE
add wave -noupdate -radix decimal /pcap_core_tb/uut/pcap_core_inst/pcap_actv_o
add wave -noupdate -radix decimal -radixshowbase 0 /pcap_core_tb/DATA
add wave -noupdate -radix decimal /pcap_core_tb/DATA_WSTB
add wave -noupdate -radix decimal -radixshowbase 0 /pcap_core_tb/pcap_dat_o
add wave -noupdate -radix decimal /pcap_core_tb/pcap_dat_valid_o
add wave -noupdate -radix decimal /pcap_core_tb/ERROR

add wave -group "TB" -radix Decimal \
"sim:/pcap_core_tb/*"

add wave -group "Core" -radix Decimal \
"sim:/pcap_core_tb/uut/pcap_core_inst/*"

add wave -group "Buffer" -radix Decimal \
"sim:/pcap_core_tb/uut/pcap_core_inst/pcap_buffer/*"

add wave -group "Frame" -radix Decimal \
"sim:/pcap_core_tb/uut/pcap_core_inst/pcap_frame/*"

add wave -group "Processing-1" \
"sim:/pcap_core_tb/uut/pcap_core_inst/pcap_frame/PROC_OTHERS(1)/pcap_posproc_encoder/*"



run -all
