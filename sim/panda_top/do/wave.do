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

