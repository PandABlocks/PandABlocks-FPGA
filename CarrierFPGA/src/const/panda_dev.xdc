# Using PMOD 1
set_property PACKAGE_PIN AA17 [get_ports {spi_sclk_i}]; # PMOD1_D0_N
set_property PACKAGE_PIN AA16 [get_ports {spi_sclk_o}]; # PMOD1_D0_P
set_property PACKAGE_PIN AB11 [get_ports {spi_dat_i }]; # PMOD1_D1_N
set_property PACKAGE_PIN AA11 [get_ports {spi_dat_o }]; # PMOD1_D1_P

# FMC CARRIER TEST BOARD
set_property PACKAGE_PIN L6  [get_ports {Am0_pad_io[0]      }];   #LA06_P
set_property PACKAGE_PIN R5  [get_ports {Bm0_pad_io[0]      }];   #LA10_P
set_property PACKAGE_PIN P6  [get_ports {Zm0_pad_io[0]      }];   #LA14_P
set_property PACKAGE_PIN L4  [get_ports {As0_pad_io[0]      }];   #LA17_CC_N
set_property PACKAGE_PIN K8  [get_ports {Bs0_pad_io[0]      }];   #LA23_N
set_property PACKAGE_PIN M7  [get_ports {Zs0_pad_io[0]      }];   #LA23_N

set_property PACKAGE_PIN F7  [get_ports {enc0_ctrl_pad_i[0] }];   #
set_property PACKAGE_PIN A5  [get_ports {enc0_ctrl_pad_i[1] }];   #
set_property PACKAGE_PIN E7  [get_ports {enc0_ctrl_pad_i[2] }];   #
set_property PACKAGE_PIN A4  [get_ports {enc0_ctrl_pad_i[3] }];   #

set_property PACKAGE_PIN E8  [get_ports {enc0_ctrl_pad_o[0] }];   #
set_property PACKAGE_PIN D3  [get_ports {enc0_ctrl_pad_o[1] }];   #
set_property PACKAGE_PIN D8  [get_ports {enc0_ctrl_pad_o[2] }];   #
set_property PACKAGE_PIN C3  [get_ports {enc0_ctrl_pad_o[3] }];   #
set_property PACKAGE_PIN D1  [get_ports {enc0_ctrl_pad_o[4] }];   #
set_property PACKAGE_PIN A2  [get_ports {enc0_ctrl_pad_o[5] }];   #
set_property PACKAGE_PIN C1  [get_ports {enc0_ctrl_pad_o[6] }];   #
set_property PACKAGE_PIN A1  [get_ports {enc0_ctrl_pad_o[7] }];   #
set_property PACKAGE_PIN E2  [get_ports {enc0_ctrl_pad_o[8] }];   #
set_property PACKAGE_PIN D7  [get_ports {enc0_ctrl_pad_o[9] }];   #
set_property PACKAGE_PIN D2  [get_ports {enc0_ctrl_pad_o[10]}];   #
set_property PACKAGE_PIN D6  [get_ports {enc0_ctrl_pad_o[11]}];   #

set_property PACKAGE_PIN F1  [get_ports {lvdsin_pad_i[0]}];       #
set_property PACKAGE_PIN F2  [get_ports {lvdsin_pad_i[1]}];       #

set_property PACKAGE_PIN H3  [get_ports {lvdsout_pad_o[0]}];      #
set_property PACKAGE_PIN H4  [get_ports {lvdsout_pad_o[1]}];      #

# PlaceHolder : ADV7511 HDMI Output - Bank 35
set_property PACKAGE_PIN  P7 [get_ports {Am0_pad_io[1]}];
set_property PACKAGE_PIN  R7 [get_ports {Bm0_pad_io[1]}];
set_property PACKAGE_PIN  N4 [get_ports {Zm0_pad_io[1]}];
set_property PACKAGE_PIN  N3 [get_ports {As0_pad_io[1]}];
set_property PACKAGE_PIN  M2 [get_ports {Bs0_pad_io[1]}];
set_property PACKAGE_PIN  M1 [get_ports {Zs0_pad_io[1]}];
set_property PACKAGE_PIN  K4 [get_ports {Am0_pad_io[2]}];
set_property PACKAGE_PIN  K3 [get_ports {Bm0_pad_io[2]}];
set_property PACKAGE_PIN  J3 [get_ports {Zm0_pad_io[2]}];
set_property PACKAGE_PIN  K2 [get_ports {As0_pad_io[2]}];
set_property PACKAGE_PIN  L2 [get_ports {Bs0_pad_io[2]}];
set_property PACKAGE_PIN  L1 [get_ports {Zs0_pad_io[2]}];
set_property PACKAGE_PIN  P3 [get_ports {Am0_pad_io[3]}];
set_property PACKAGE_PIN  P2 [get_ports {Bm0_pad_io[3]}];
set_property PACKAGE_PIN  N1 [get_ports {Zm0_pad_io[3]}];
set_property PACKAGE_PIN  P1 [get_ports {As0_pad_io[3]}];
set_property PACKAGE_PIN  K7 [get_ports {Bs0_pad_io[3]}];
set_property PACKAGE_PIN  L7 [get_ports {Zs0_pad_io[3]}];

# PlaceHolder : FMC Expansion Connector - Bank 34
set_property PACKAGE_PIN  T1 [get_ports {ttlin_pad_i[0]}];        #
set_property PACKAGE_PIN  T2 [get_ports {ttlin_pad_i[1]}];        #
set_property PACKAGE_PIN  R8 [get_ports {ttlin_pad_i[2]}];        #
set_property PACKAGE_PIN  R2 [get_ports {ttlin_pad_i[3]}];        #
set_property PACKAGE_PIN  R3 [get_ports {ttlin_pad_i[4]}];        #
set_property PACKAGE_PIN  M6 [get_ports {ttlin_pad_i[5]}];        #
set_property PACKAGE_PIN  K5 [get_ports {ttlout_pad_o[0]}];       #
set_property PACKAGE_PIN  J5 [get_ports {ttlout_pad_o[1]}];       #
set_property PACKAGE_PIN  J6 [get_ports {ttlout_pad_o[2]}];       #
set_property PACKAGE_PIN  J7 [get_ports {ttlout_pad_o[3]}];       #
set_property PACKAGE_PIN  U1 [get_ports {ttlout_pad_o[4]}];       #
set_property PACKAGE_PIN  U2 [get_ports {ttlout_pad_o[5]}];       #
set_property PACKAGE_PIN  B6 [get_ports {ttlout_pad_o[6]}];       #
set_property PACKAGE_PIN  B7 [get_ports {ttlout_pad_o[7]}];       #
set_property PACKAGE_PIN  N5 [get_ports {ttlout_pad_o[8]}];       #
set_property PACKAGE_PIN  N6 [get_ports {ttlout_pad_o[9]}];       #

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# SPI Clock Constraints
create_generated_clock -name slowctrl_inst/slowctrl_block_inst/slowctrl_inst/sclk_prebuf -source [get_pins {ps/processing_system7_0/inst/PS7_i/FCLKCLK[0]}] -divide_by 16 [get_pins {slowctrl_inst/slowctrl_block_inst/slowctrl_inst/sclk_prebuf_reg/Q}]

