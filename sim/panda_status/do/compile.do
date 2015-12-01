vlib work

vcom -explicit  -93 "../../../src/hdl/defines/type_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/top_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/addr_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/panda_status.vhd"
vcom -explicit  -93 "../bench/panda_status_tb.vhd"

vsim -voptargs="+acc" -t 1ps  -lib work work.panda_status_tb

view wave

do wave.do

run 10us
