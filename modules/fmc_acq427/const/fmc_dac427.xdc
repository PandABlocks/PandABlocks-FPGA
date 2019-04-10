create_generated_clock -name softblocks_inst/{{ block.name }}_inst/THE_ACQ427FMC_DAC_INTERFACE/I -source [get_pins {ps/processing_system7_0/inst/PS7_i/FCLKCLK[0]}] -divide_by 2 [get_pins softblocks_inst/{{ block.name }}_inst/THE_ACQ427FMC_DAC_INTERFACE/clk_62_5M_raw_reg/Q]

