create_clock -period 8.005 [get_ports EXTCLK_P]
set_input_jitter [get_clocks -of_objects [get_ports EXTCLK_P]] 0.08005000000000001

create_generated_clock -name clk1mux -divide_by 1 -add -master_clock clk_fpga_0 -source [get_pins BUFGMUX_inst/I0] [get_pins BUFGMUX_inst/O]
create_generated_clock -name clk2mux -divide_by 1 -add -master_clock EXTCLK_P -source [get_pins BUFGMUX_inst/I1] [get_pins BUFGMUX_inst/O]
set_clock_groups -physically_exclusive -group clk1mux -group clk2mux        
        
set_false_path -from [get_pins {slowcont_inst/slow_ctrl_inst/EXT_CLOCK_reg[0]/C}] -to [get_pins BUFGMUX_inst/CE1] 
set_false_path -from [get_pins enable_ext_clock_reg/C] -to [get_pins BUFGMUX_inst/CE1]

