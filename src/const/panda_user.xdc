# ----------------------------------------------------------------------------
# User LEDs - Bank 35
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y18 [get_ports {leds[0]        }];
set_property PACKAGE_PIN Y19 [get_ports {leds[1]        }];

set_property PACKAGE_PIN L6  [get_ports {A0_pad_i       }];   #LA06_P
set_property PACKAGE_PIN R5  [get_ports {B0_pad_i       }];   #LA10_P
set_property PACKAGE_PIN P6  [get_ports {Z0_pad_i       }];   #LA14_P
set_property PACKAGE_PIN L4  [get_ports {A0_pad_o       }];   #LA17_CC_N
set_property PACKAGE_PIN K8  [get_ports {B0_pad_o       }];   #LA23_N
set_property PACKAGE_PIN M7  [get_ports {Z0_pad_o       }];   #LA26_N

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];


