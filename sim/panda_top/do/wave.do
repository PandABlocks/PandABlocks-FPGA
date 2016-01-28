add wave -divider {Encoder IO}
add wave \
sim:/test/tb/uut/Am0_pad_io \
sim:/test/tb/uut/As0_pad_io \
sim:/test/tb/uut/Bm0_pad_io \
sim:/test/tb/uut/Bs0_pad_io \
sim:/test/tb/uut/Zm0_pad_io \
sim:/test/tb/uut/Zs0_pad_io

add wave -divider {Blocks}
add wave -group "TB"    sim:/test/tb/*
add wave -group "TOP"   sim:/test/tb/uut/*
add wave -group "PS"    sim:/test/tb/uut/ps/ps/*
add wave -group "CSR"   sim:/test/tb/uut/panda_csr_if_inst/*
