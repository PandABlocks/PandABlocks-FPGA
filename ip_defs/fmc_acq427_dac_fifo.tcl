#
# Create Standard Asymmetric 1K, 128-bit(WR), 32-bit(RD) FIFO IP for ACQ427 DAC FMC
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
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

