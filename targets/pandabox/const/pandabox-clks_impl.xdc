# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_fpga_0]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks EXTCLK_P]
set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group GTXCLK1_P

set_clock_groups -quiet -logically_exclusive -group fclk_clk -group fclk_clk_1 -group fclk_clk_2
set_clock_groups -quiet -logically_exclusive -group fclk_clk_2x -group fclk_clk_2x_1 -group fclk_clk_2x_2
set_clock_groups -quiet -logically_exclusive -group pll2_clkfbout -group pll2_clkfbout_1 -group pll2_clkfbout_2

set_clock_groups -quiet -logically_exclusive -group fclk_clk -group fclk_clk_2x_1
set_clock_groups -quiet -logically_exclusive -group fclk_clk -group fclk_clk_2x_2
set_clock_groups -quiet -logically_exclusive -group fclk_clk_1 -group fclk_clk_2x
set_clock_groups -quiet -logically_exclusive -group fclk_clk_1 -group fclk_clk_2x_2
set_clock_groups -quiet -logically_exclusive -group fclk_clk_2 -group fclk_clk_2x
set_clock_groups -quiet -logically_exclusive -group fclk_clk_2 -group fclk_clk_2x_1

