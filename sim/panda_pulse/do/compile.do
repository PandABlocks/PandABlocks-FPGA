set FIFO {../../../src/ip_repo/pulse_queue}

vlib work
vlib msim

vlib msim/fifo_generator_v12_0
vlib msim/xil_defaultlib

vmap fifo_generator_v12_0 msim/fifo_generator_v12_0
vmap xil_defaultlib msim/xil_defaultlib


vcom -64 -93 -work fifo_generator_v12_0 \
"${FIFO}/fifo_generator_v12_0/simulation/fifo_generator_vhdl_beh.vhd" \
"${FIFO}/fifo_generator_v12_0/hdl/fifo_generator_v12_0_vh_rfs.vhd"


vcom -64 -93 -work xil_defaultlib   \
"${FIFO}/sim/pulse_queue.vhd"       \
"../../../src/hdl/panda_pulse.vhd"  \
"../bench/panda_pulse_tb.vhd"

vopt -64 +acc -L secureip -L fifo_generator_v12_0 -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_pulse_tb -o panda_pulse_opt

vsim -t 1ps -novopt -lib xil_defaultlib panda_pulse_tb

view wave

add wave -position insertpoint sim:/panda_pulse_tb/uut/*

run 6us
