# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------

set_clock_groups -asynchronous -group clk_fpga_0
set_clock_groups -asynchronous -group clk_fpga_1
set_clock_groups -asynchronous -group EXTCLK_P
set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group GTXCLK1_P

create_generated_clock -quiet -name pll2_clkin1_out0 -master_clock sma_clk_out1 \
    [get_pins mmcm_clkmux_inst/plle2_adv_inst2/CLKOUT0]
create_generated_clock -quiet -name pll2_clkin2_out0 -master_clock clk_fpga_0 \
    [get_pins mmcm_clkmux_inst/plle2_adv_inst2/CLKOUT0]

create_generated_clock -quiet -name pll2_clkin1_out1 -master_clock sma_clk_out1 \
    [get_pins mmcm_clkmux_inst/plle2_adv_inst2/CLKOUT1]
create_generated_clock -quiet -name pll2_clkin2_out1 -master_clock clk_fpga_0 \
    [get_pins mmcm_clkmux_inst/plle2_adv_inst2/CLKOUT1]

set_clock_groups -quiet -physically_exclusive -group pll2_clkin1_out0 -group pll2_clkin2_out0
set_clock_groups -quiet -physically_exclusive -group pll2_clkin1_out1 -group pll2_clkin2_out1

set_clock_groups -quiet -physically_exclusive -group pll2_clkin1_out0 -group pll2_clkin2_out1
set_clock_groups -quiet -physically_exclusive -group pll2_clkin2_out0 -group pll2_clkin1_out1

