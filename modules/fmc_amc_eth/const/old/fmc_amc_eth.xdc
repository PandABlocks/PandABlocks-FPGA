# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
# Programmable oscillator on board for FMC MGTs (default frequency - 125 MHz)
create_clock -period 8.000 [get_ports GTXCLK0_P]
## Programmable oscillator on board for bank 110 (default frequency - 156.25 MHz)
#create_clock -period 6.400 [get_ports GTXCLK1_P]
#
## Programmable oscillator on FMC card for FMC MGTs (frequency set to 125 MHz)
#create_clock -period 8.000  [get_ports FMC_CLK0_M2C_P]
## Programmable oscillator on FMC card for bank 110  (not available on Techway FMC_SFP/+_104)
#create_clock -period 8.000  [get_ports FMC_CLK1_M2C_P]

# -------------------------------------------------------------------
# AMC Clock Timing Constraints
# -------------------------------------------------------------------

## Programmable oscillator for AMC P4-P7 MGTs (default frequency - 100 MHz)
#create_clock -period 10.000 [get_ports AMC4_7_MGTREFCLK0_P]
## Programmable oscillator for AMC P4-P7 MGTs (default frequency - 156.25 MHz)
#create_clock -period 6.400 [get_ports AMC4_7_MGTREFCLK1_P]
#
## Clock provided from AMC FCLKA pins for AMC P8-P11 MGTs 
#create_clock -period 8.000 [get_ports AMC8_11_MGTREFCLK0_P]
# Programmable oscillator for AMC P8-P11 MGTs (default frequency - 125 MHz)
#create_clock -period 8.000  [get_ports AMC8_11_MGTREFCLK1_P]
