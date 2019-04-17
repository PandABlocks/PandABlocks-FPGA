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
