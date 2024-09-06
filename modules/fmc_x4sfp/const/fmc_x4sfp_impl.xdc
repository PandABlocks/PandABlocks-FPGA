# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group FMC_CLK0_M2C_P[0]
set_clock_groups -asynchronous -group FMC_CLK1_M2C_P[0]

# -------------------------------------------------------------------
# Override Differential Pairs' IOSTANDARD
# -------------------------------------------------------------------
set_property IOSTANDARD LVDS    [get_ports FMC_CLK0_M2C_P[0]]
set_property IOSTANDARD LVDS    [get_ports FMC_CLK1_M2C_P[0]]

