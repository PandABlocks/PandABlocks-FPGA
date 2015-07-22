vlib work

vcom -explicit  -93 "../../../src/hdl/defines/type_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/top_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/defines/addr_defines.vhd"
vcom -explicit  -93 "../../../src/hdl/panda_pcomp.vhd"
vcom -explicit  -93 "../../panda_top/bench/test_interface.vhd"
vcom -explicit  -93 "../bench/panda_pcomp_tb.vhd"

vsim -voptargs="+acc" -novopt -t 1ns  -lib work work.panda_pcomp_tb

view wave

add wave *

run 50ms
