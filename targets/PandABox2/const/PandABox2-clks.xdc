# Clock constraints for clocks provided as inputs to the core
# Note: the IP core-level XDC constrains clocks produced by the core, which drive user clocks via helper blocks
# ----------------------------------------------------------------------------------------------------------------------
create_clock -period 8.000 [get_ports GTXCLK0_P]
create_clock -period 8.000 [get_ports GTXCLK1_P]

set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group GTXCLK1_P

