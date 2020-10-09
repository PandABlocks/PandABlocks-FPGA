#
# Create Standard 1Kx32-bit FIFO IP
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
-module_name fifo_1K32 -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips fifo_1K32]

generate_target all [get_files $BUILD_DIR/fifo_1K32/fifo_1K32.xci]
synth_ip [get_ips fifo_1K32]

