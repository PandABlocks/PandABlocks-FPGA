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
# OLED display on ZedBoard
# 

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.2 \
-module_name charLib -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {8} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File $TARGET_DIR/etc/characterLib.coe \
    CONFIG.Read_Width_A {8} \
    CONFIG.Write_Width_B {8} \
    CONFIG.Read_Width_B {8} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Port_A_Write_Rate {0} \
    CONFIG.Port_B_Clock {0}\
    CONFIG.Port_B_Enable_Rate {0} \
] [get_ips charLib]

generate_target all [get_files $BUILD_DIR/charLib/charLib.xci]
synth_ip [get_ips charLib]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.2 \
-module_name pixel_buffer -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.Write_Width_A {8} \
    CONFIG.Write_Depth_A {512} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Read_Width_A {8} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Write_Width_B {8} \
    CONFIG.Read_Width_B {8} \
    CONFIG.Operating_Mode_B {READ_FIRST} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
] [get_ips pixel_buffer]

generate_target all [get_files  $BUILD_DIR/pixel_buffer/pixel_buffer.xci]
synth_ip [get_ips pixel_buffer]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.2 \
-module_name init_sequence_rom -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File $TARGET_DIR/etc/init_sequence.coe \
    CONFIG.Port_A_Write_Rate {0} \
] [get_ips init_sequence_rom]

generate_target all [get_files  $BUILD_DIR/init_sequence_rom/init_sequence_rom.xci]
synth_ip [get_ips init_sequence_rom]

# Close project if not gui mode
if {[string match "gui" [string tolower $MODE]]} { return }
close_project
exit
