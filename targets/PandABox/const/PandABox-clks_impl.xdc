# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------

set_clock_groups -asynchronous -group clk_fpga_0
set_clock_groups -asynchronous -group EXTCLK_P
set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group GTXCLK1_P

# Pack IOB registers
set_property iob true [get_cells -hierarchical -regexp -filter {NAME =~ .*iob_reg.*}]

