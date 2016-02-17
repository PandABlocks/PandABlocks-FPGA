vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -64 -93 -work xil_defaultlib  \
"../../../src/hdl/defines/type_defines.vhd" \
"../../../src/hdl/defines/top_defines.vhd"  \
"../../../src/hdl/defines/addr_defines.vhd" \
"../../../src/hdl/panda_spbram.vhd"         \
"../../../src/hdl/panda_sequencer_table.vhd"      \
"../../../src/hdl/panda_sequencer.vhd"      \

# Compile Testbench
vlog -work xil_defaultlib "../bench/panda_sequencer_tb.v" \
"../../panda_top/bench/glbl.v"

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_sequencer_tb -o panda_sequencer_tb_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib panda_sequencer_tb_opt

view wave
do wave.do
#add wave -group "TB"    "sim:/panda_sequencer_tb/*"
#add wave -group "UUT"   "sim:/panda_sequencer_tb/uut/*"
add wave -group "TABLE" "sim:/panda_sequencer_tb/uut/sequencer_table/*"


run 500us
