create_clock -period 8.005 [get_ports EXTCLK_P]
set_input_jitter [get_clocks -of_objects [get_ports EXTCLK_P]] 0.08005000000000001
               
