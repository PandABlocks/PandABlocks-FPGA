# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous  \
-group clk_fpga_0 \
-group clk_fpga_1 \
-group FMC_CLK0_M2C_P \
-group FMC_CLK1_M2C_P \
-group [get_clocks -filter {NAME =~ *TXOUTCLK}] \
-group EXTCLK_P \

