vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -64 -93 -work xil_defaultlib   \
"../../../src/hdl/defines/type_defines.vhd" \
"../../../src/hdl/defines/top_defines.vhd"  \
"../../../src/hdl/defines/addr_defines.vhd" \
"../../../src/hdl/panda_pcomp.vhd"

vlog -work xil_defaultlib \
"../bench/panda_pcomp_tb.v" \
"/dls_sw/FPGA/Xilinx/14.7/ISE_DS/ISE//verilog/src/glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_pcomp_tb -o panda_pcomp_opt glbl

vsim -t 1ps -voptargs=+acc -lib xil_defaultlib panda_pcomp_tb

view wave

do wave.do

run 5000us
