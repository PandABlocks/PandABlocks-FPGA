# Programmable oscillator for SFPs (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports GTXCLK0_P]
# Programmable oscillator for SFPs (default frequency - 125 MHz) ??? - CHECK FREQ?
create_clock -period 6.400 [get_ports GTXCLK1_P]
# External SMA clock (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports EXTCLK_P]
