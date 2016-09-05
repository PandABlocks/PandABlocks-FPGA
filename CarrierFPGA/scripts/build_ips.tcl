# Source directory
set SRCDIR [lindex $argv 0]
set_param board.repoPaths $SRCDIR/configs

# Build directory
set origin_dir [lindex $argv 1]/ip_repo

# Create Managed IP Project
create_project managed_ip_project $origin_dir/managed_ip_project -part xc7z030sbg485-1 -ip

set_property target_language VHDL [current_project]
set_property target_simulator ModelSim [current_project]

#
# Create PULSE_QUEUE IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pulse_queue -dir $origin_dir/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {49}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {49}   \
] [get_ips pulse_queue]

generate_target all [get_files $origin_dir/pulse_queue/pulse_queue.xci]
synth_ip [get_ips pulse_queue]

#
# Create PCAP DMA FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pcap_dma_fifo -dir $origin_dir/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
] [get_ips pcap_dma_fifo]

generate_target all [get_files $origin_dir/pcap_dma_fifo/pcap_dma_fifo.xci]
synth_ip [get_ips pcap_dma_fifo]

#
# Create PGEN DMA FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pgen_dma_fifo -dir $origin_dir/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
] [get_ips pgen_dma_fifo]

generate_target all [get_files $origin_dir/pgen_dma_fifo/pgen_dma_fifo.xci]
synth_ip [get_ips pgen_dma_fifo]

#
# Create PCOMP DMA FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pcomp_dma_fifo -dir $origin_dir/

set_property -dict [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Use_Extra_Logic {true}   \
    CONFIG.Write_Data_Count {true}  \
    CONFIG.Output_Data_Width {64}   \
] [get_ips pcomp_dma_fifo]

generate_target all [get_files $origin_dir/pcomp_dma_fifo/pcomp_dma_fifo.xci]
synth_ip [get_ips pcomp_dma_fifo]


#
# Create ILA IP (32-bit wide with 8K Depth)
#
create_ip -name ila -vendor xilinx.com -library ip -version 5.1 \
-module_name ila_32x8K -dir $origin_dir/

set_property -dict [list \
    CONFIG.C_PROBE0_WIDTH {32}  \
    CONFIG.C_DATA_DEPTH {8192}  \
] [get_ips ila_32x8K]

generate_target all [get_files $origin_dir/ila_32x8K/ila_32x8K.xci]
synth_ip [get_ips ila_32x8K]

#
# Create FMC GTX Aurora IP
#
create_ip -name gtwizard -vendor xilinx.com -library ip -version 3.5 \
-module_name fmcgtx -dir $origin_dir/

set_property -dict [list \
    CONFIG.identical_protocol_file {aurora_8b10b_single_lane_2byte} \
    CONFIG.gt0_val {true}                                           \
    CONFIG.gt0_val_tx_refclk {REFCLK1_Q0}                           \
    CONFIG.identical_val_tx_line_rate {3.125}                       \
    CONFIG.identical_val_tx_reference_clock {156.250}               \
    CONFIG.identical_val_rx_line_rate {3.125}                       \
    CONFIG.identical_val_rx_reference_clock {156.250}               \
] [get_ips fmcgtx]

generate_target all [get_files $origin_dir/fmcgtx/fmcgtx.xci]
synth_ip [get_ips fmcgtx]

#
# Create SFP GTX Aurora IP
#
create_ip -name gtwizard -vendor xilinx.com -library ip -version 3.5 \
-module_name sfpgtx -dir $origin_dir/


set_property -dict [list \
    CONFIG.identical_protocol_file {aurora_8b10b_single_lane_2byte} \
    CONFIG.gt0_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt0_val {true}                                           \
    CONFIG.gt1_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt1_val {true}                                           \
    CONFIG.gt2_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt2_val {true}                                           \
    CONFIG.identical_val_tx_line_rate {2.5}                         \
    CONFIG.identical_val_tx_reference_clock {125.000}               \
    CONFIG.identical_val_rx_line_rate {2.5}                         \
    CONFIG.identical_val_rx_reference_clock {125.000}               \
] [get_ips sfpgtx]

generate_target all [get_files $origin_dir/sfpgtx/sfpgtx.xci]
synth_ip [get_ips sfpgtx]

# Close project
close_project
exit
