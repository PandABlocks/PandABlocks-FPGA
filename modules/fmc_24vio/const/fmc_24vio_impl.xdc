# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
#create_clock -period 6.400  [get_ports FMC_CLK0_M2C_P]
#create_clock -period 6.400  [get_ports FMC_CLK1_M2C_P]

# -------------------------------------------------------------------
# Override Differential Pairs' IOSTANDARD
# -------------------------------------------------------------------
#set_property IOSTANDARD LVDS    [get_ports FMC_CLK0_M2C_P]
#set_property IOSTANDARD LVDS    [get_ports FMC_CLK1_M2C_P]

# -------------------------------------------------------------------
# Enable on-chip pulldown for floating FMC_IN[0-7] inputs
# -------------------------------------------------------------------
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_P[*]]
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_N[*]]

##set_property IO_BUFFER_TYPE none [get_ports FMC_DP0_C2M_P]
##set_property IO_BUFFER_TYPE none [get_ports FMC_DP0_C2M_N]

set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/FMC_24V_IN_inst/fmcgtx_exdes_i/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# FMC MGTs - Bank 112
# -------------------------------------------------------------------
set_property LOC $FMC_GTX_LOC \
[get_cells softblocks_inst/FMC_24V_IN_inst/fmcgtx_exdes_i/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]

