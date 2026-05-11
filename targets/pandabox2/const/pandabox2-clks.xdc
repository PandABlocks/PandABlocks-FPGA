# Clock constraints for clocks provided as inputs to the core
create_clock -period 8.000 -name mgt_refclk1_in0 [get_ports MGT_REFCLK1_IN0_P]
set_clock_groups -asynchronous -group mgt_refclk1_in0

set_property CLOCK_DELAY_GROUP grp_clk0_clk0_4x [get_nets {clk0 clk0_4x}]
