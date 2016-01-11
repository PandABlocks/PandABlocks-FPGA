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
# Create PCAP FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pcap_fifo -dir $origin_dir/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
] [get_ips pcap_fifo]

generate_target all [get_files $origin_dir/pcap_fifo/pcap_fifo.xci]
synth_ip [get_ips pcap_fifo]
