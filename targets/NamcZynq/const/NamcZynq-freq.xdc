# -------------------------------------------------------------------
# On-board Clocks from APP PLL
# -------------------------------------------------------------------
# APP PLL OUT5 - Bank 9 (AD18/AD19) 100 Mhz  IO_L12P/N_T1_MRCC_9
# APP PLL OUT6 - Bank 9 (AA18/AA19) 100 Mhz  IO_L13P/N_T2_MRCC_9

create_clock -period 10.000 [get_ports ZCLK_APPOUT0_P]
create_clock -period 10.000 [get_ports ZCLK_APPOUT1_P]

# -------------------------------------------------------------------
# MGT REF CLKS
# -------------------------------------------------------------------
# - Bank 109 -
# - MGTREFCLK0 : FMC_CLK0_M2C_P  Programmable OSC on FMC card for FMC MGTs (frequency set to 125 MHz)
# - MGTREFCLK1 : GTXCLK0_P       Programmable OSC on board for FMC MGTs (default frequency - 125 MHz)
# -------------------------------------------------------------------
create_clock -period 8.000  [get_ports GTXCLK0_P]
create_clock -period 8.000  [get_ports FMC_CLK0_M2C_P]

# -------------------------------------------------------------------
# - Bank 110 -
# - MGTREFCLK0 : FMC_CLK1_M2C_P - Programmable OSC on FMC card for bank 110
#                                 (not available on Techway FMC_SFP/+_104)
# - MGTREFCLK1 : GTXCLK1_P      - Programmable OSC on board for bank 110 (default frequency - 156.25 MHz)
# -------------------------------------------------------------------
create_clock -period 6.400  [get_ports GTXCLK1_P]
create_clock -period 8.000  [get_ports FMC_CLK1_M2C_P]


# -------------------------------------------------------------------
# - Bank 111 -
# - MGTREFCLK0 : AMC8_11_MGTREFCLK0_P - Clock provided from AMC FCLKA pins for AMC P8-P11 MGTs
# - MGTREFCLK1 : AMC8_11_MGTREFCLK1_P - Programmable OSC for AMC P8-P11 MGTs (default frequency - 125 MHz)
# -------------------------------------------------------------------
create_clock -period 8.000  [get_ports AMC8_11_MGTREFCLK0_P]
create_clock -period 8.000  [get_ports AMC8_11_MGTREFCLK1_P]


# -------------------------------------------------------------------
# - Bank 112 -
# - MGTREFCLK0 : AMC4_7_MGTREFCLK0_P - Programmable OSC for AMC P4-P7 MGTs (default frequency - 100 MHz)
# - MGTREFCLK1 : AMC4_7_MGTREFCLK1_P - Programmable OSC for AMC P4-P7 MGTs (default frequency - 156.25 MHz)
# -------------------------------------------------------------------
create_clock -period 10.000 [get_ports AMC4_7_MGTREFCLK0_P]
create_clock -period 6.400  [get_ports AMC4_7_MGTREFCLK1_P]


