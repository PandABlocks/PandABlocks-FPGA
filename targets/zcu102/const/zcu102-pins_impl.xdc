

# I2C FPGA
#set_property -dict {PACKAGE_PIN AG10  IOSTANDARD LVCMOS18  } [get_ports {I2C_SCL_FPGA}]
#set_property -dict {PACKAGE_PIN AH10  IOSTANDARD LVCMOS18  } [get_ports {I2C_SDA_FPGA}]

# MGT Reference Clocks
set_property PACKAGE_PIN C7 [get_ports GTXCLK0_N]
set_property PACKAGE_PIN C8 [get_ports GTXCLK0_P]
#set_property PACKAGE_PIN V5 [get_ports GTXCLK1_N]
#set_property PACKAGE_PIN V6 [get_ports GTXCLK1_P]

set SFP1_LOC GTHE4_CHANNEL_X1Y12
set SFP2_LOC GTHE4_CHANNEL_X1Y13
set SFP3_LOC GTHE4_CHANNEL_X1Y14
set SFP4_LOC GTHE4_CHANNEL_X1Y15

