#set_false_path -from [get_clocks clk_fpga_0] -through [get_pins -hierarchical -filter {NAME=~ "*ACQ427*SEL_CLK_SEL/O"}] -to [get_clocks clk_fpga_0]
