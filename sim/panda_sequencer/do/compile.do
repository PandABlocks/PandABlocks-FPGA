vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -64 -93 -work xil_defaultlib  \
"../../../src/hdl/defines/type_defines.vhd" \
"../../../src/hdl/defines/top_defines.vhd"  \
"../../../src/hdl/defines/addr_defines.vhd" \
"../../../src/hdl/panda_spbram.vhd"         \
"../../../src/hdl/panda_sequencer.vhd"      \
"../../panda_top/bench/test_interface.vhd"  \
"../bench/panda_sequencer_tb.vhd"

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_sequencer_tb -o panda_sequencer_tb_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib panda_sequencer_tb_opt

view wave
do wave.do
#add wave /panda_sequencer_tb/uut/*

run 500us
