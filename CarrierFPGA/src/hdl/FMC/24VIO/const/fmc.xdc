# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
create_clock -period 6.400  [get_ports FMC_CLK0_M2C_P]
create_clock -period 6.400  [get_ports FMC_CLK1_M2C_P]

# -------------------------------------------------------------------
# Async false reset paths
# -------------------------------------------------------------------
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_on_error_in_r*/D}]


