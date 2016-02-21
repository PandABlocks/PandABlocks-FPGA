add wave -divider {TESTBENCH}
add wave -radix unsigned -group "TEST"  "sim:/test/*"
add wave -radix unsigned -group "TB"    "sim:/test/tb/*"
add wave -radix unsigned -group "TOP"   "sim:/test/tb/uut/*"
add wave -radix unsigned -group "PS"    "sim:/test/tb/uut/ps/ps/*"
add wave -radix unsigned -group "CSR"   "sim:/test/tb/uut/panda_csr_if_inst/*"

add wave -divider {SEQUENCER}
add wave -group "Block" -radix decimal \
"sim:/test/tb/uut/SEQ_GEN/seq_inst/SEQ_GEN(0)/panda_sequencer_block/*"
add wave -group "Sequencer" -radix decimal \
"sim:/test/tb/uut/SEQ_GEN/seq_inst/SEQ_GEN(0)/panda_sequencer_block/panda_sequencer/*"

add wave -divider {POSITION CAPTURE}
add wave -group "DMA Engine" -radix decimal \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_dma_inst/*"
add wave -group "PCap Core" -radix decimal \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_core/*"
add wave -group "Arming" -radix decimal \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_core/pcap_arming/*"

#add wave -divider {TEST BENCH}
#add wave -group "Encoder Model" \
#"sim:/test/tb/encoder/*"
#add wave -group "Daughter Card"\
#"sim:/test/tb/DCARD(0)/daughter_card/*"
#add wave -group "SN75LBC175A" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN75LBC175A_inst/*"
#add wave -group "SN75LBC174A" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN75LBC174A_inst/*"
#add wave -group "DATA_IN_P" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN65HVD05D_u10/*"
#add wave -group "CLK_OUT_P" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN65HVD05D_u12/*"
#add wave -group "DATA_OUT_P" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN65HVD05D_u15/*"
#add wave -group "CLK_IN_P" \
#"sim:/test/tb/DCARD(0)/daughter_card/SN65HVD05D_u16/*"
#
#
add wave -divider {ENCODER}
add wave -group "Input Encoder 0" \
"sim:/test/tb/uut/INENC_GEN/inenc_inst/*"
#
#add wave -group "Output Encoder 0" \
#"sim:/test/tb/uut/OUTENC_GEN/outenc_inst/*"
#
#add wave -group "SSI Master" \
#"sim:/test/tb/uut/INENC_GEN/inenc_inst/INENC_GEN(0)/panda_inenc_block_inst/panda_inenc_inst/panda_ssimstr_inst/*"
#add wave -group "SSI Slave" \
#"sim:/test/tb/uut/OUTENC_GEN/outenc_inst/ENCOUT_GEN(0)/panda_outenc_block_inst/panda_outenc_inst/panda_ssislv_inst/*"

add wave -divider {PCOMPARE}
add wave -group "Block 0" -radix Decimal \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(0)/pcomp_block_inst/*"
add wave -group "Pulse 0" -radix Decimal \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(0)/pcomp_block_inst/pcomp_inst/*"
add wave -group "Block 1" -radix Decimal \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(1)/pcomp_block_inst/*"
add wave -group "Pulse 1" -radix Decimal \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(1)/pcomp_block_inst/pcomp_inst/*"
