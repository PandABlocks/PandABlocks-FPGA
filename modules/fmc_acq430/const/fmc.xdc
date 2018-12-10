create_generated_clock -name FMC_GEN.fmc_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q -source [get_pins FMC_GEN.fmc_inst/FCLK_CLK0] -divide_by 4 -add -master_clock clk_fpga_0 [get_pins FMC_GEN.fmc_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q]

