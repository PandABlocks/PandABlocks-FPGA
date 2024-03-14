# Clock constraints for clocks provided as inputs to the core
# Note: the IP core-level XDC constrains clocks produced by the core, which drive user clocks via helper blocks
# ----------------------------------------------------------------------------------------------------------------------
create_clock -period 8.000 -name clk_mgtrefclk1_x0y1_p [get_ports mgtrefclk1_x0y1_p]
set_clock_groups -asynchronous -group clk_mgtrefclk1_x0y1_p

