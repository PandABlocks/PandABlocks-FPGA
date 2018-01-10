# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------

create_generated_clock -name clk1mux -divide_by 1 -add -master_clock clk_fpga_0 -source [get_pins BUFGMUX_inst/I0] [get_pins BUFGMUX_inst/O]
create_generated_clock -name clk2mux -divide_by 1 -add -master_clock EXTCLK_P -source [get_pins BUFGMUX_inst/I1] [get_pins BUFGMUX_inst/O]
set_clock_groups -physically_exclusive -group clk1mux -group clk2mux
 
create_generated_clock -name clk1mux_cas -divide_by 1 -add -master_clock clk1mux -source [get_pins eventr_BUFGMUX_inst/I0] [get_pins eventr_BUFGMUX_inst/O]
create_generated_clock -name clk2mux_cas -divide_by 1 -add -master_clock clk2mux -source [get_pins eventr_BUFGMUX_inst/I0] [get_pins eventr_BUFGMUX_inst/O]
create_generated_clock -name clk3mux -divide_by 1 -add -master_clock eventr_plle2_adv_inst_n_11 -source [get_pins eventr_BUFGMUX_inst/I1] [get_pins eventr_BUFGMUX_inst/O]
set_clock_groups -physically_exclusive -group clk1mux_cas -group clk2mux_cas -group clk3mux

set_clock_groups -asynchronous  \
-group clk_fpga_0 \
-group FMC_CLK0_M2C_P \
-group FMC_CLK1_M2C_P \
-group [get_clocks -filter {NAME =~ *TXOUTCLK}] \
-group EXTCLK_P \
-group [get_clocks GTXCLK0_P] \

set_clock_groups -asynchronous \
-group [get_clocks -of_objects [get_pins eventr_plle2_adv_inst/CLKOUT0]] \
-group [get_clocks clk1mux_cas] \
-group [get_clocks clk2mux_cas] \
-group [get_clocks clk_fpga_0] \
-group [get_clocks GTXCLK0_P] \

set_clock_groups -asynchronous \
-group [get_clocks GTXCLK0_P] \
-group [get_clocks clk1mux_cas] \
-group [get_clocks clk2mux_cas] \
-group [get_clocks clk3mux] \

set_clock_groups -asynchronous \
-group [get_clocks clk_fpga_0] \
-group [get_clocks clk2mux] \
-group [get_clocks clk2mux_cas] \
-group [get_clocks clk3mux] \

set_clock_groups -asynchronous \
-group [get_clocks clk1mux_cas] -group [get_clocks clk1mux_cas] \

set_clock_groups -asynchronous \
-group [get_clocks clk2mux_cas] -group [get_clocks clk2mux_cas] \

set_clock_groups -asynchronous \
-group [get_clocks clk3mux] -group [get_clocks clk3mux] \


# Pack IOB registers
set_property iob true [get_cells -hierarchical -regexp -filter {NAME =~ .*iob_reg.*}]
