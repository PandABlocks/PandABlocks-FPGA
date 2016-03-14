add wave -noupdate -divider {Testbench}
add wave -group "TB" "sim:/test/tb/*"
add wave -group "SSI Slave" "sim:/test/tb/SSI_SLAVE/*"
add wave -group "SSI Master" "sim:/test/tb/SSI_MASTER/*"
add wave -group "Daughter" "sim:/test/tb/DCARD(0)/daughter_card/*"
add wave -noupdate -divider {Slow FPGA}
add wave -group "Slow Top" \
"sim:/test/tb/slow_top_inst/*"
add wave -group "Serial" \
"sim:/test/tb/slow_top_inst/serial_if_inst/*"
add wave -group "TX" \
"sim:/test/tb/slow_top_inst/serial_if_inst/slowctrl_inst/slow_tx_inst/*"
add wave -group "RX" \
"sim:/test/tb/slow_top_inst/serial_if_inst/slowctrl_inst/slow_rx_inst/*"


add wave -noupdate -divider {Panda Busses}
add wave -group "Busses" \
"sim:/test/tb/uut/busses_inst/*"

add wave -noupdate -divider {Position Compare}
add wave -radix Decimal -group "Ctrl" \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(0)/pcomp_block_inst/pcomp_ctrl/*"
add wave -radix Decimal -group "PComp" \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(0)/pcomp_block_inst/pcomp_inst/*"
add wave -radix Decimal -group "Table" \
"sim:/test/tb/uut/PCOMP_GEN/pcomp_inst/PCOMP_GEN(0)/pcomp_block_inst/table_inst/*"

add wave -noupdate -divider {Position Capture}
add wave -radix Decimal -group "Top" \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/*"
add wave -radix Decimal -group "Ctrl" \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_ctrl_inst/*"
add wave -radix Decimal -group "PCap" \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_core/*"
add wave -radix Decimal -group "DMA" \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_dma_inst/*"
add wave -group "Framing" \
"sim:/test/tb/uut/PCAP_GEN/pcap_inst/pcap_core/pcap_frame/*"

add wave -noupdate -divider {Position Encoder}
add wave -group "Counter Block" \
"sim:/test/tb/uut/counter_inst/COUNTER_GEN(0)/counter_block_inst/*"
add wave -group "Posenc Block" \
"sim:/test/tb/uut/posenc_inst/POSENC_GEN(0)/posenc_block_inst/*"
add wave -group "QDec Block" \
"sim:/test/tb/uut/qdec_inst/QDEC_GEN(0)/qdec_block_inst/*"
add wave -group "Posenc" \
"sim:/test/tb/uut/posenc_inst/POSENC_GEN(0)/posenc_block_inst/posenc_inst/*"
add wave -group "Quadout" \
"sim:/test/tb/uut/posenc_inst/POSENC_GEN(0)/posenc_block_inst/posenc_inst/qenc/*"
