set SRC {../../../src/hdl}

vlib work
vlib msim

vlib msim/xil_defaultlib
vmap xil_defaultlib msim/xil_defaultlib

# Compile Sources
#
vcom -64 -93 -work xil_defaultlib  \
"${SRC}/panda_ssimstr.vhd" \
"${SRC}/panda_ssislv.vhd" \
"../bench/panda_ssi_tb.vhd"

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -work xil_defaultlib xil_defaultlib.panda_ssi_tb -o test_opt

vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib test_opt

add wave *

add wave -group "Master" -radix unsigned sim:/panda_ssi_tb/master/*
add wave -group "Slave" -radix unsigned sim:/panda_ssi_tb/slave/*

run 5000 us
