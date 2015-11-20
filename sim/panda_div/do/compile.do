#
# Create work library
#
vlib work
#
# Compile sources
#
vcom -explicit  -93 "../../../src/hdl/panda_div.vhd"
vcom -explicit  -93 "../bench/panda_div_tb.vhd"

vsim -voptargs="+acc" -t 1ps  -lib work work.panda_div_tb

view wave

add wave -position insertpoint sim:/panda_div_tb/uut/*

run 6us
