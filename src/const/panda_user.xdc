# ----------------------------------------------------------------------------
# User LEDs - Bank 35
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN "AA11"  [get_ports "leds[0]"]
set_property PACKAGE_PIN "AB11"  [get_ports "leds[1]"]

set_property iostandard "LVCMOS18" [get_ports "leds[0]"]
set_property iostandard "LVCMOS18" [get_ports "leds[1]"]
