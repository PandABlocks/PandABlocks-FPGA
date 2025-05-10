# Clock constraints for clocks provided as inputs to the core
# Note: the IP core-level XDC constrains clocks produced by the core, which drive user clocks via helper blocks
# ----------------------------------------------------------------------------------------------------------------------
create_clock -period 8.000 [get_ports GTXCLK0_P]

create_clock -name FMC_HPC0_GBTCLK0_M2C_C_P -period 6.4 [get_ports FMC_HPC0_GBTCLK0_M2C_C_P]
create_clock -name FMC_HPC0_GBTCLK1_M2C_C_P -period 6.4 [get_ports FMC_HPC0_GBTCLK1_M2C_C_P]

set_clock_groups -asynchronous -group GTXCLK0_P
set_clock_groups -asynchronous -group FMC_HPC0_GBTCLK0_M2C_C_P
set_clock_groups -asynchronous -group FMC_HPC0_GBTCLK1_M2C_C_P

