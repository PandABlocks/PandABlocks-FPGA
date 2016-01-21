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

add wave -group "COUNTER_0" \
sim:/test/tb/uut/panda_counter_inst/COUNTER_GEN(0)/panda_counter_block/*

add wave -group "COUNTER_1" \
sim:/test/tb/uut/panda_counter_inst/COUNTER_GEN(1)/panda_counter_block/*

add wave -group "INENC_TOP" \
sim:/test/tb/uut/panda_inenc_inst/*

add wave -group "INENC_BLOCK0" \
sim:/test/tb/uut/panda_inenc_inst/INENC_GEN(0)/panda_inenc_block_inst/*

add wave -group "INENC_BLOCK1" \
sim:/test/tb/uut/panda_inenc_inst/INENC_GEN(1)/panda_inenc_block_inst/*

add wave -group "OUTENC_TOP" \
sim:/test/tb/uut/panda_outenc_inst/*

add wave -group "OUTENC_BLOCK0" \
sim:/test/tb/uut/panda_outenc_inst/ENCOUT_GEN(0)/panda_outenc_block_inst/*

add wave -group "OUTENC_BLOCK1" \
sim:/test/tb/uut/panda_outenc_inst/ENCOUT_GEN(1)/panda_outenc_block_inst/*

add wave -group "ENC_MODEL" \
sim:/test/tb/encoder/*

add wave -group "DAUGHTER_MODEL" \
sim:/test/tb/DCARD(0)/daughter_card/*

add wave -group "SLOW" \
sim:/test/tb/uut/panda_slowctrl_inst/*

add wave -group "PCAP_BLOCK" \
sim:/test/tb/uut/panda_pcap_inst/*

add wave -group "PCAP" \
sim:/test/tb/uut/panda_pcap_inst/panda_pcap_inst/*

add wave -group "pcomp_block" \
sim:/test/tb/uut/panda_pcomp_inst/PCOMP_GEN(0)/panda_pcomp_block_inst/*

add wave -group "pcomp" \
sim:/test/tb/uut/panda_pcomp_inst/PCOMP_GEN(0)/panda_pcomp_block_inst/panda_pcomp_inst/*
