set FIFO {../../../output/ip_repo/pulse_queue}

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
"../../../src/hdl/panda_pulse.vhd"

vlog -work xil_defaultlib \
"../bench/panda_pulse_tb.v" \
"/dls_sw/FPGA/Xilinx/14.7/ISE_DS/ISE//verilog/src/glbl.v"

vopt -64 +acc -L secureip -L fifo_generator_v12_0 -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_pulse_tb -o panda_pulse_opt glbl

vsim -t 1ps -novopt -lib xil_defaultlib panda_pulse_tb

view wave

add wave -radix decimal -group "Testbench" \
        sim:/panda_pulse_tb/*

add wave -radix decimal -group "Pulse" \
        sim:/panda_pulse_tb/uut/*

#do wave.do

run 5us
