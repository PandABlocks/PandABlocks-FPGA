vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib


vcom -64 -93 -work xil_defaultlib   \
"../../../src/hdl/panda_lut.vhd"

vlog -work xil_defaultlib \
"../bench/panda_lut_tb.v" \
"/dls_sw/FPGA/Xilinx/14.7/ISE_DS/ISE//verilog/src/glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_lut_tb -o panda_lut_opt glbl

vsim -t 1ps -voptargs=+acc -lib xil_defaultlib panda_lut_tb

view wave

add wave -radix decimal -group "Phyton" \
        sim:/panda_lut_tb/*

add wave -radix decimal -group "LUT" \
        sim:/panda_lut_tb/uut/*

run 5us
