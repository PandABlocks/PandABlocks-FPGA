add wave -divider {Encoder IO}
add wave \
sim:/test/tb/uut/Am0_pad_io \
sim:/test/tb/uut/As0_pad_io \
sim:/test/tb/uut/Bm0_pad_io \
sim:/test/tb/uut/Bs0_pad_io \
sim:/test/tb/uut/Zm0_pad_io \
sim:/test/tb/uut/Zs0_pad_io

add wave -divider {Blocks}
add wave -radix unsigned -group "TB"    sim:/test/tb/*
add wave -radix unsigned -group "TOP"   sim:/test/tb/uut/*
add wave -radix unsigned -group "PS"    sim:/test/tb/uut/ps/ps/*
add wave -radix unsigned -group "CSR"   sim:/test/tb/uut/panda_csr_if_inst/*

add wave -radix unsigned -group "Slow Control Block" \
sim:/test/tb/uut/slowctrl_inst/slowctrl_block_inst/*
add wave -radix unsigned -group "Slow Control" \
sim:/test/tb/uut/slowctrl_inst/slowctrl_block_inst/slowctrl_inst/*
add wave -radix unsigned -group "Slow RX" \
sim:/test/tb/uut/slowctrl_inst/slowctrl_block_inst/slowctrl_inst/slow_rx_inst/*
add wave -radix unsigned -group "Input Encoder" \
sim:/test/tb/uut/inenc_inst/*
add wave -radix unsigned -group "Input Encoder Block" \
sim:/test/tb/uut/inenc_inst/INENC_GEN(0)/panda_inenc_block_inst/*

add wave -divider {COUNTERS}
add wave -radix unsigned -group "Counter-0" \
sim:/test/tb/uut/counter_inst/COUNTER_GEN(0)/counter_block_inst/*
add wave -radix unsigned -group "Counter-1" \
sim:/test/tb/uut/counter_inst/COUNTER_GEN(1)/counter_block_inst/*

add wave -divider {SLOW CONTROLLER}
add wave -radix unsigned -group "Slow Top" \
sim:/test/tb/slow_top_inst/*
add wave -radix unsigned -group "Slow Serial IF" \
sim:/test/tb/slow_top_inst/serial_if_inst/*

add wave -divider {POSITION CAPTURE}

