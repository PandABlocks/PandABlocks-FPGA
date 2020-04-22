# Programmable oscillator for SFPs (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports GTXCLK0_P]
# Programmable oscillator for SFPs (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports GTXCLK1_P]
# External SMA clock (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports EXTCLK_P]

set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group GTXCLK1_P
set_clock_groups -asynchronous -group EXTCLK_P
