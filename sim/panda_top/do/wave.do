add wave -divider {Discrete IO}
add wave    sim:/test/tb/uut/lvdsin_pad_i  \
            sim:/test/tb/uut/lvdsout_pad_o \
            sim:/test/tb/uut/ttlin_pad_i   \
            sim:/test/tb/uut/ttlout_pad_o

add wave -divider {System Bus}
add wave    sim:/test/tb/uut/lut_val    \
            sim:/test/tb/uut/srgate_val \
            sim:/test/tb/uut/div_val    \
            sim:/test/tb/uut/pulse_val  \
            sim:/test/tb/uut/seq_val    \
            sim:/test/tb/uut/seq_active


add wave -divider {Blocks}
add wave -group "TB"    sim:/test/tb/*
add wave -group "TOP"   sim:/test/tb/uut/*
add wave -group "PS"    sim:/test/tb/uut/ps/ps/*
add wave -group "CSR"   sim:/test/tb/uut/panda_csr_if_inst/*
add wave -group "TTL"   sim:/test/tb/uut/panda_ttl_inst/*
add wave -group "LUT0"  sim:/test/tb/uut/panda_lut_inst/LUT_GEN(0)/panda_lut_block/*
add wave -group "SR0" \
sim:/test/tb/uut/panda_srgate_inst/SRGATE_GEN(0)/panda_srgate_block/*

add wave -group "DIV0" \
sim:/test/tb/uut/panda_div_inst/DIV_GEN(0)/panda_div_block/*

add wave -group "PULSE BLOCK" \
sim:/test/tb/uut/panda_pulse_inst/PULSE_GEN(0)/panda_pulse_block/*

add wave -group "PULS0" \
sim:/test/tb/uut/panda_pulse_inst/PULSE_GEN(0)/panda_pulse_block/panda_pulse/*

add wave -group "SEQ_BLOCK-0"  \
sim:/test/tb/uut/panda_seq_inst/SEQ_GEN(0)/panda_sequencer_block/*

add wave -group "SEQ-0" \
sim:/test/tb/uut/panda_seq_inst/SEQ_GEN(0)/panda_sequencer_block/panda_sequencer/*

add wave -group "BITS BLOCK" \
sim:/test/tb/uut/panda_bits_inst/panda_bits_block/*

add wave -group "BITS" \
sim:/test/tb/uut/panda_bits_inst/panda_bits_block/panda_bits_inst/*

add wave sim:/test/tb/uut/sysbus
