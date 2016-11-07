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

# -------------------------------------------------------------------
# Enable on-chip pulldown for floating FMC_IN[0-7] inputs
# -------------------------------------------------------------------
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_P[*]]
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_N[*]]

# -------------------------------------------------------------------
# Forwarded clocks
# -------------------------------------------------------------------
create_generated_clock -name {FMC_LA_P[1]} -source [get_pins {FMC_GEN.fmc_inst/fmc_acq420_inst/ADCS[0].adc_inst/oddr_inst/C}] -divide_by 1 [get_ports {FMC_LA_P[1]}]
create_generated_clock -name {FMC_LA_P[7]} -source [get_pins {FMC_GEN.fmc_inst/fmc_acq420_inst/ADCS[2].adc_inst/oddr_inst/C}] -divide_by 1 [get_ports {FMC_LA_P[7]}]
create_generated_clock -name {FMC_LA_P[8]} -source [get_pins {FMC_GEN.fmc_inst/fmc_acq420_inst/ADCS[1].adc_inst/oddr_inst/C}] -divide_by 1 [get_ports {FMC_LA_P[8]}]
create_generated_clock -name {FMC_LA_P[12]} -source [get_pins {FMC_GEN.fmc_inst/fmc_acq420_inst/ADCS[3].adc_inst/oddr_inst/C}] -divide_by 1 [get_ports {FMC_LA_P[12]}]

