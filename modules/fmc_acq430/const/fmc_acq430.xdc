create_generated_clock -name softblocks_inst/{{ block.name }}_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q -source [get_pins ps/FCLK_CLK0] -divide_by 4 [get_pins softblocks_inst/{{ block.name }}_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q]

