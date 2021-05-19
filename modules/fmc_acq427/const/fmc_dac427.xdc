create_generated_clock -name softblocks_inst/{{ block.name }}_inst/THE_ACQ427FMC_DAC_INTERFACE/I -source [get_pins mmcm_clkmux_inst/fclk_clk0_o] -divide_by 2 -add -master_clock clk_fpga_0 [get_pins softblocks_inst/{{ block.name }}_inst/THE_ACQ427FMC_DAC_INTERFACE/clk_62_5M_raw_reg/Q]

