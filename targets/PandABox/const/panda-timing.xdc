# External SMA clock
create_clock -period 8.000 [get_ports EXTCLK_P]
# Programmable oscillator for SFPs (default frequency)
create_clock -period 8.000 [get_ports GTXCLK0_P]

