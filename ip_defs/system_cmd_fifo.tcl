#
# Create System FPGA Command FIFO
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
-module_name system_cmd_fifo -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {42}    \
    CONFIG.Output_Data_Width {42}   \
] [get_ips system_cmd_fifo]

generate_target all [get_files $BUILD_DIR/system_cmd_fifo/system_cmd_fifo.xci]

