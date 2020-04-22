# -------------------------------------------------------------------
# AMC Clock Timing Constraints
# -------------------------------------------------------------------
#create_clock -period 8.0  [get_ports GTXCLK0_P]
#create_clock -period 8.0  [get_ports GTXCLK1_P]

#create_clock -period 6.4 [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*TXOUTCLK}]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*TXOUTCLK}]]
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ *data_sync_reg1}]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*TXOUTCLK}]]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*TXOUTCLK}]] -to [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]]
#
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*RXOUTCLK}]]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_amcgtx_i*gtxe2_i*RXOUTCLK}]] -to [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]]
