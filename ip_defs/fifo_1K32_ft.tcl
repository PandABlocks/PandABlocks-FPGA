#
# Create Standard 1Kx32-bit first word fall through FIFO IP
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
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
