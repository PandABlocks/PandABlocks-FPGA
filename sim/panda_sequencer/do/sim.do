vlib work

vcom -explicit  -93 "../../../src/hdl/defines/type_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/top_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/addr_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/panda_sequencer.vhd"
vcom -explicit  -93 "../../panda_top/bench/test_interface.vhd"
vcom -explicit  -93 "../bench/panda_sequencer_tb.vhd"

vsim -novopt -t 1ps  -lib work work.panda_sequencer_tb

view wave

add wave /panda_sequencer_tb/uut/*

run 500us
