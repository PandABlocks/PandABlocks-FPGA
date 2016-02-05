vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib


vcom -64 -93 -work xil_defaultlib       \
"../../../src/hdl/pulse2pulse.vhd"      \
"../../../src/hdl/panda_slow_rx.vhd"    \
"../../../src/hdl/panda_slow_tx.vhd"    \
"../../../src/hdl/panda_slowctrl.vhd"

vlog -work xil_defaultlib \
"../bench/panda_slowctrl_tb.v" \
"../bench/glbl.v"

vopt -64 +acc -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_slowctrl_tb -o panda_slowctrl_opt glbl

vsim -t 1ps -novopt -lib xil_defaultlib panda_slowctrl_tb

view wave

add wave sim:/panda_slowctrl_tb/uut/*

#add wave -radix unsigned -group "Testbench" \
#        sim:/panda_slowctrl_tb/*
#
#add wave -radix unsigned -group "UUT" \
#        sim:/panda_slowctrl_tb/uut/*
#
#add wave -radix unsigned -group "SPI_Slave" \
#        sim:/panda_slowctrl_tb/slow_spicore_inst/*

run 50us
