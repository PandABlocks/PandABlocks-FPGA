set origin_dir ./ip_repo

set_param board.repoPaths ../configs

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
