# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous  \
-group clk_fpga_0 \
-group EXTCLK_P \

# Pack IOB registers
set_property iob true [get_cells -hierarchical -regexp -filter {NAME =~ .*iob_reg.*}]
