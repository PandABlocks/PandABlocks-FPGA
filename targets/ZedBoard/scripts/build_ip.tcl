#
# Generate Xilinx IP Cores
#

# Source directory
set TARGET_DIR [lindex $argv 0]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 1]

# Vivado run mode - gui or batch mode
set MODE [lindex $argv 2]

# Create Managed IP Project
create_project -part xc7z020clg484-1 -force -ip managed_ip_project $BUILD_DIR/managed_ip_project

set_property target_language VHDL [current_project]
set_property target_simulator ModelSim [current_project]

#
# Create PULSE_QUEUE IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pulse_queue -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {49}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {49}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips pulse_queue]

generate_target all [get_files $BUILD_DIR/pulse_queue/pulse_queue.xci]
synth_ip [get_ips pulse_queue]

#
# Create Standard 1Kx32-bit FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name fifo_1K32 -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips fifo_1K32]

generate_target all [get_files $BUILD_DIR/fifo_1K32/fifo_1K32.xci]
synth_ip [get_ips fifo_1K32]

#
# Create Standard 1Kx32-bit first word fall through FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name fifo_1K32_ft -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips fifo_1K32_ft]

generate_target all [get_files $BUILD_DIR/fifo_1K32_ft/fifo_1K32_ft.xci]
synth_ip [get_ips fifo_1K32_ft]






#
# Create System FPGA Command FIFO
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name system_cmd_fifo -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {42}    \
    CONFIG.Output_Data_Width {42}   \
] [get_ips system_cmd_fifo]

generate_target all [get_files $BUILD_DIR/system_cmd_fifo/system_cmd_fifo.xci]
synth_ip [get_ips system_cmd_fifo]

#
# Create Standard Asymmetric 1K, 32-bit(WR), 256-bit(RD) FIFO IP for ACQ430 FMC
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name fmc_acq430_ch_fifo -dir $BUILD_DIR/

set_property -dict [list \
        CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
        CONFIG.Input_Data_Width {32} \
        CONFIG.Input_Depth {256} \
        CONFIG.Output_Data_Width {256} \
        CONFIG.Read_Data_Count {true} \
        CONFIG.Output_Depth {32} \
        CONFIG.Reset_Type {Asynchronous_Reset} \
        CONFIG.Full_Flags_Reset_Value {1} \
        CONFIG.Data_Count_Width {8} \
        CONFIG.Write_Data_Count_Width {8} \
        CONFIG.Read_Data_Count_Width {5} \
        CONFIG.Full_Threshold_Assert_Value {253} \
        CONFIG.Full_Threshold_Negate_Value {252}
] [get_ips fmc_acq430_ch_fifo]

generate_target all [get_files $BUILD_DIR/fmc_acq430_ch_fifo/fmc_acq430_ch_fifo.xci]
synth_ip [get_ips fmc_acq430_ch_fifo]

#
# Create low level ACQ430 FMC Sample RAM
#
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 \
-module_name fmc_acq430_sample_ram -dir $BUILD_DIR/

set_property -dict [list \
        CONFIG.depth {32} \
        CONFIG.data_width {24} \
        CONFIG.memory_type {dual_port_ram} \
        CONFIG.output_options {registered} \
        CONFIG.common_output_clk {true}
] [get_ips fmc_acq430_sample_ram]

generate_target all [get_files $BUILD_DIR/fmc_acq430_sample_ram/fmc_acq430_sample_ram.xci]
synth_ip [get_ips fmc_acq430_sample_ram]

#
# Create Standard Asymmetric 1K, 128-bit(WR), 32-bit(RD) FIFO IP for ACQ427 DAC FMC
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name fmc_acq427_dac_fifo -dir $BUILD_DIR/

set_property -dict [list \
        CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
        CONFIG.Input_Data_Width {128} \
        CONFIG.Input_Depth {16} \
        CONFIG.Output_Data_Width {32} \
        CONFIG.Write_Data_Count {true} \
        CONFIG.Read_Data_Count {true} \
        CONFIG.Output_Depth {64} \
        CONFIG.Reset_Type {Asynchronous_Reset} \
        CONFIG.Full_Flags_Reset_Value {1} \
        CONFIG.Data_Count_Width {4} \
        CONFIG.Write_Data_Count_Width {4} \
        CONFIG.Read_Data_Count_Width {6} \
        CONFIG.Full_Threshold_Assert_Value {13} \
        CONFIG.Full_Threshold_Negate_Value {12}
] [get_ips fmc_acq427_dac_fifo]

generate_target all [get_files $BUILD_DIR/fmc_acq427_dac_fifo/fmc_acq427_dac_fifo.xci]
synth_ip [get_ips fmc_acq427_dac_fifo]

#
# Create ILA IP (32-bit wide with 8K Depth)
#
create_ip -name ila -vendor xilinx.com -library ip -version 5.1 \
-module_name ila_32x8K -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.C_PROBE0_WIDTH {32}  \
    CONFIG.C_DATA_DEPTH {8192}  \
] [get_ips ila_32x8K]

generate_target all [get_files $BUILD_DIR/ila_32x8K/ila_32x8K.xci]
synth_ip [get_ips ila_32x8K]





#
# Create ILA chipscope
create_ip -name ila -vendor xilinx.com -library ip -version 5.1 \
-module_name ila_0 -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.C_DATA_DEPTH {2048}  \
    CONFIG.C_PROBE12_WIDTH {16} \
    CONFIG.C_PROBE11_WIDTH {2}  \
    CONFIG.C_PROBE10_WIDTH {16} \
    CONFIG.C_PROBE6_WIDTH {16}  \
    CONFIG.C_PROBE5_WIDTH {2}   \
    CONFIG.C_PROBE4_WIDTH {2}   \
    CONFIG.C_NUM_OF_PROBES {13} \
    CONFIG.C_TRIGOUT_EN {false} \
    CONFIG.C_TRIGIN_EN {false}  \
] [get_ips ila_0]

generate_target all [get_files $BUILD_DIR/ila_0/ila_0.xci]
synth_ip [get_ips ila_0]

#
# Create Memory
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.2 \
-module_name sfp_transmit_mem -dir $BUILD_DIR/

set_property -dict [list                                                            \
    CONFIG.Write_Depth_A {4096}                                                     \
    CONFIG.Operating_Mode_A {READ_FIRST}                                            \
    CONFIG.Load_Init_File {true}                                                    \
    CONFIG.Coe_File $TARGET_DIR/../../tests/sim/sfp_receiver/mem/event_receiver_mem.coe \
    CONFIG.Use_RSTA_Pin {false}                                                     \
] [get_ips sfp_transmit_mem]

generate_target all [get_files $BUILD_DIR/sfp_transmit_mem/sfp_transmit_mem.xci]
synth_ip [get_ips sfp_transmit_mem]


# Close project if not gui mode
if {[string match "gui" [string tolower $MODE]]} { return }
close_project
exit
