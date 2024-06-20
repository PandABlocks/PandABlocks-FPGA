# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
create_clock -period 6.400  [get_ports FMC_CLK0_M2C_P[0]]
create_clock -period 6.400  [get_ports FMC_CLK1_M2C_P[0]]

