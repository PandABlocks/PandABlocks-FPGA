#
# Create Standard Asymmetric 1K, 32-bit(WR), 256-bit(RD) FIFO IP for ACQ430 FMC
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
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
