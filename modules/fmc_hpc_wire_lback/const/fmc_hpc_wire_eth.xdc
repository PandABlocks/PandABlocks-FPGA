# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
create_clock -period 8.0  [get_ports FMC_CLK0_M2C_P]
create_clock -period 8.0  [get_ports FMC_CLK1_M2C_P]

