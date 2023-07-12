#
# Create PULSE_QUEUE IP
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}]\
-module_name pulse_queue -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {49}    \
    CONFIG.Input_Depth {256}        \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {49}   \
    CONFIG.Output_Depth {256}       \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips pulse_queue]

