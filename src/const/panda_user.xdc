# ----------------------------------------------------------------------------
# User LEDs - Bank 35
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y18 [get_ports {leds[0]            }];
set_property PACKAGE_PIN Y19 [get_ports {leds[1]            }];

set_property PACKAGE_PIN L6  [get_ports {Am0_pad_io         }];   #LA06_P
set_property PACKAGE_PIN R5  [get_ports {Bm0_pad_io         }];   #LA10_P
set_property PACKAGE_PIN P6  [get_ports {Zm0_pad_io         }];   #LA14_P
set_property PACKAGE_PIN L4  [get_ports {As0_pad_io         }];   #LA17_CC_N
set_property PACKAGE_PIN K8  [get_ports {Bs0_pad_io         }];   #LA23_N
set_property PACKAGE_PIN M7  [get_ports {Zs0_pad_io         }];   #LA26_N

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

# DUMMY PINS ON FMC - START
set_property PACKAGE_PIN F5  [get_ports {ttlin_pad_i[0]}];        #
set_property PACKAGE_PIN E5  [get_ports {ttlin_pad_i[1]}];        #
set_property PACKAGE_PIN E4  [get_ports {ttlin_pad_i[2]}];        #
set_property PACKAGE_PIN E3  [get_ports {ttlin_pad_i[3]}];        #
set_property PACKAGE_PIN B2  [get_ports {ttlin_pad_i[4]}];        #
set_property PACKAGE_PIN B1  [get_ports {ttlin_pad_i[5]}];        #

set_property PACKAGE_PIN H1  [get_ports {ttlout_pad_o[0]}];       #
set_property PACKAGE_PIN G1  [get_ports {ttlout_pad_o[1]}];       #
set_property PACKAGE_PIN A7  [get_ports {ttlout_pad_o[2]}];       #
set_property PACKAGE_PIN A6  [get_ports {ttlout_pad_o[3]}];       #
set_property PACKAGE_PIN C8  [get_ports {ttlout_pad_o[4]}];       #
set_property PACKAGE_PIN B8  [get_ports {ttlout_pad_o[5]}];       #
set_property PACKAGE_PIN B7  [get_ports {ttlout_pad_o[6]}];       #
set_property PACKAGE_PIN B6  [get_ports {ttlout_pad_o[7]}];       #
set_property PACKAGE_PIN G8  [get_ports {ttlout_pad_o[8]}];       #
set_property PACKAGE_PIN G7  [get_ports {ttlout_pad_o[9]}];       #

set_property PACKAGE_PIN G6  [get_ports {lvdsin_pad_i[0]}];       #
set_property PACKAGE_PIN F6  [get_ports {lvdsin_pad_i[1]}];       #

set_property PACKAGE_PIN G4  [get_ports {lvdsout_pad_o[0]}];      #
set_property PACKAGE_PIN F4  [get_ports {lvdsout_pad_o[1]}];      #
# DUMMY PINS ON FMC - END

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];


