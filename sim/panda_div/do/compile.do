vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib


vcom -64 -93 -work xil_defaultlib   \
"../../../src/hdl/panda_div.vhd"

vlog -work xil_defaultlib \
"../bench/panda_div_tb.v" \
"/dls_sw/FPGA/Xilinx/14.7/ISE_DS/ISE//verilog/src/glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_div_tb -o panda_div_opt glbl

vsim -t 1ps -novopt -lib xil_defaultlib panda_div_tb

view wave

add wave -radix decimal -group "Testbench" \
        sim:/panda_div_tb/*

add wave -radix decimal -group "DIV" \
        sim:/panda_div_tb/uut/*

#do wave.do

run 5us
