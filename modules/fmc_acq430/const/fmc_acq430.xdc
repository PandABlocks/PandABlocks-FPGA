create_generated_clock -name softblocks_inst/{{ block.name }}_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q -source [get_pins softblocks_inst/{{ block.name }}*_inst/FCLK_CLK0] -divide_by 4 -add -master_clock clk_fpga_0 [get_pins softblocks_inst/{{ block.name }}_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q]

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/THE_ACQ430FMC_INTERFACE/s_CLK_GEN_CLK_reg/Q}]
