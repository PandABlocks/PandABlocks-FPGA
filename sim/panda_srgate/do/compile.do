vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib


vcom -64 -93 -work xil_defaultlib   \
"../../../src/hdl/panda_srgate.vhd"

vlog -work xil_defaultlib \
"../bench/panda_srgate_tb.v" \
"../bench/glbl.v"

vopt -64 +acc -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_srgate_tb -o panda_srgate_opt glbl

vsim -t 1ps -voptargs=+acc -lib xil_defaultlib panda_srgate_tb

view wave

add wave -radix decimal -group "Phyton" \
        sim:/panda_srgate_tb/*

add wave -radix decimal -group "SRGATE" \
        sim:/panda_srgate_tb/uut/*

run 5us
