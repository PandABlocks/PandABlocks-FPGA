#
# Create Standard Asymmetric 256 x 16-bit FIFO IP for FMC-ADC100M
#
create_ip -vlnv [get_ipdefs -filter {NAME == fifo_generator}] \
-module_name fmc_adc100m_ch_fifo -dir $BUILD_DIR/

set_property -dict [list \
        CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
        CONFIG.INTERFACE_TYPE {Native} \
        CONFIG.Performance_Options {Standard_FIFO} \
        CONFIG.Input_Data_Width {16} \
        CONFIG.Input_Depth {256} \
        CONFIG.Output_Data_Width {16} \
        CONFIG.Output_Depth {256} \
        CONFIG.Reset_Type {Asynchronous_Reset} \
        CONFIG.Enable_Reset_Synchronization {true} \
        CONFIG.Enable_Safety_Circuit {false} \
        CONFIG.Full_Flags_Reset_Value {1} \
        CONFIG.Use_Dout_Reset {true} \
        CONFIG.Data_Count_Width {8} \
        CONFIG.Write_Data_Count_Width {8} \
        CONFIG.Read_Data_Count {true} \
        CONFIG.Read_Data_Count_Width {8}
] [get_ips fmc_adc100m_ch_fifo]

generate_target all [get_files $BUILD_DIR/fmc_adc100m_ch_fifo/fmc_adc100m_ch_fifo.xci]
synth_ip [get_ips fmc_adc100m_ch_fifo]
