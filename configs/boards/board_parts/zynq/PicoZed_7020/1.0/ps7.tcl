# ----------------------------------------------------------------------------
#     _____
#    /     \
#   /____   \____
#  / \===\   \==/
# /___\===\___\/  AVNET PicoZed 7010/7020 Presets
#      \======/         www.PicoZed.org
#       \====/    
# ----------------------------------------------------------------------------
# 
#  Revision History
#    22 Aug 2013 -- Initial release
#    20 Sep 2013 -- Changed SDIO clock to 50 MHz
#                   Changed FCLK1 to 100 MHz to better match the ZED Display
#    22 May 2014 -- Updated to work with Vivado Design Suite 2013.3 and
#                   match parameters from Developing Zynq Hardware with 
#                   Vivado 2013.3 SpeedWay training
#    22 May 2014 -- Added support for Vivado 2014.1 and 2014.2
#    05 Oct 2014 -- Added PicoZed eMMC @ 50MHz
#
#  Please direct any questions to:
#     PicoZed Support Forums
#     www.PicoZed.org/forums
#
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2014 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
 
############################################################################
# PS Bank Voltage, Busses, Clocks 
############################################################################
proc apply_ps7_board_setting { ps7_ip } {
set_property -dict [ list \
	CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
	CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
	CONFIG.PCW_PACKAGE_NAME {clg400} \
	CONFIG.PCW_USE_M_AXI_GP0 {0} \
	CONFIG.PCW_USE_M_AXI_GP1 {0} \
	CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} \
	CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
	CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
	CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
	CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
	CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
	CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
	CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
	CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333333} \
	CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
	CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
	CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
	CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {50} \
	CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
	CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
	CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
	CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
] [get_bd_cells $ps7_ip]

############################################################################
# Fabric Clocks - CLK0 enabled, CLK[3:1] disabled by default
############################################################################
set_property -dict [ list \
	CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
	CONFIG.PCW_FCLK_CLK0_BUF {true} \
	CONFIG.PCW_FCLK_CLK1_BUF {false} \
	CONFIG.PCW_FCLK_CLK2_BUF {false} \
	CONFIG.PCW_FCLK_CLK3_BUF {false} \
	CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
	CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {100} \
	CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {33.333333} \
	CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
	CONFIG.PCW_EN_CLK0_PORT {1} \
	CONFIG.PCW_EN_CLK1_PORT {0} \
	CONFIG.PCW_EN_CLK2_PORT {0} \
	CONFIG.PCW_EN_CLK3_PORT {0} \
	CONFIG.PCW_EN_RST0_PORT {1} \
	CONFIG.PCW_EN_RST1_PORT {0} \
	CONFIG.PCW_EN_RST2_PORT {0} \
	CONFIG.PCW_EN_RST3_PORT {0} \
] [get_bd_cells ]

############################################################################
# DDR3 
############################################################################
set_property -dict [ list \
	CONFIG.PCW_EN_DDR {1} \
	CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
	CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
	CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
	CONFIG.PCW_UIPARAM_DDR_T_RC {48.75} \
	CONFIG.PCW_UIPARAM_DDR_CWL {6} \
	CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
	CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
	CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
	CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {39.7} \
	CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {39.7} \
	CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {54.14} \
	CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {54.14} \
	CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {49.59} \
	CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {51.74} \
	CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {50.32} \
	CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {48.55} \
	CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {50.05} \
	CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {50.43} \
	CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {50.10} \
	CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {50.01} \
	CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
	CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
	CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
	CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {-0.073} \
	CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {-0.072} \
	CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.024} \
	CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.023} \
	CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.294} \
	CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.298} \
	CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.338} \
	CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.334} \
	CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} \
] [get_bd_cells processing_system7_0]

############################################################################
# Peripheral assignments
#   with the exception of GPIO:
#   		eMMC/Pmod Mux Select: 0
#   		Pmod:                 9
#   		DIP Switch:           50
#   		PB:                   51 
############################################################################
set_property -dict [ list \
	CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
	CONFIG.PCW_USB0_RESET_IO {MIO 7} \
	CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
 	CONFIG.PCW_SD1_SD1_IO {MIO 10 .. 15} \
	CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
	CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
	CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
	CONFIG.PCW_SD0_GRP_CD_IO {MIO 46} \
	CONFIG.PCW_ENET0_RESET_IO {MIO 47} \
	CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
	CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
	CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
] [get_bd_cells processing_system7_0]

############################################################################
# Enable Peripherals 
############################################################################
set_property -dict [ list \
	CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
	CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
	CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
	CONFIG.PCW_ENET0_RESET_ENABLE {1} \
	CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
	CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
	CONFIG.PCW_SD1_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
	CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
	CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {1} \
	CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
	CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
	CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
] [get_bd_cells processing_system7_0]

############################################################################
# Configure MIOs
#   - disable all pull-ups
#   - slew set to SLOW
############################################################################
set_property -dict [ list \
	CONFIG.PCW_MIO_0_PULLUP {disabled} \
	CONFIG.PCW_MIO_1_PULLUP {disabled} \
	CONFIG.PCW_MIO_2_PULLUP {disabled} \
	CONFIG.PCW_MIO_3_PULLUP {disabled} \
	CONFIG.PCW_MIO_4_PULLUP {disabled} \
	CONFIG.PCW_MIO_5_PULLUP {disabled} \
	CONFIG.PCW_MIO_6_PULLUP {disabled} \
	CONFIG.PCW_MIO_7_PULLUP {disabled} \
	CONFIG.PCW_MIO_8_PULLUP {disabled} \
	CONFIG.PCW_MIO_9_PULLUP {disabled} \
	CONFIG.PCW_MIO_10_PULLUP {disabled} \
	CONFIG.PCW_MIO_11_PULLUP {disabled} \
	CONFIG.PCW_MIO_12_PULLUP {disabled} \
	CONFIG.PCW_MIO_13_PULLUP {disabled} \
	CONFIG.PCW_MIO_14_PULLUP {disabled} \
	CONFIG.PCW_MIO_15_PULLUP {disabled} \
	CONFIG.PCW_MIO_16_PULLUP {disabled} \
	CONFIG.PCW_MIO_17_PULLUP {disabled} \
	CONFIG.PCW_MIO_18_PULLUP {disabled} \
	CONFIG.PCW_MIO_19_PULLUP {disabled} \
	CONFIG.PCW_MIO_20_PULLUP {disabled} \
	CONFIG.PCW_MIO_21_PULLUP {disabled} \
	CONFIG.PCW_MIO_22_PULLUP {disabled} \
	CONFIG.PCW_MIO_23_PULLUP {disabled} \
	CONFIG.PCW_MIO_24_PULLUP {disabled} \
	CONFIG.PCW_MIO_25_PULLUP {disabled} \
	CONFIG.PCW_MIO_26_PULLUP {disabled} \
	CONFIG.PCW_MIO_27_PULLUP {disabled} \
	CONFIG.PCW_MIO_28_PULLUP {disabled} \
	CONFIG.PCW_MIO_29_PULLUP {disabled} \
	CONFIG.PCW_MIO_30_PULLUP {disabled} \
	CONFIG.PCW_MIO_31_PULLUP {disabled} \
	CONFIG.PCW_MIO_32_PULLUP {disabled} \
	CONFIG.PCW_MIO_33_PULLUP {disabled} \
	CONFIG.PCW_MIO_34_PULLUP {disabled} \
	CONFIG.PCW_MIO_35_PULLUP {disabled} \
	CONFIG.PCW_MIO_36_PULLUP {disabled} \
	CONFIG.PCW_MIO_37_PULLUP {disabled} \
	CONFIG.PCW_MIO_38_PULLUP {disabled} \
	CONFIG.PCW_MIO_39_PULLUP {disabled} \
	CONFIG.PCW_MIO_40_PULLUP {disabled} \
	CONFIG.PCW_MIO_41_PULLUP {disabled} \
	CONFIG.PCW_MIO_42_PULLUP {disabled} \
	CONFIG.PCW_MIO_43_PULLUP {disabled} \
	CONFIG.PCW_MIO_44_PULLUP {disabled} \
	CONFIG.PCW_MIO_45_PULLUP {disabled} \
	CONFIG.PCW_MIO_46_PULLUP {disabled} \
	CONFIG.PCW_MIO_47_PULLUP {disabled} \
	CONFIG.PCW_MIO_48_PULLUP {disabled} \
	CONFIG.PCW_MIO_49_PULLUP {disabled} \
	CONFIG.PCW_MIO_50_PULLUP {disabled} \
	CONFIG.PCW_MIO_51_PULLUP {disabled} \
	CONFIG.PCW_MIO_52_PULLUP {disabled} \
	CONFIG.PCW_MIO_53_PULLUP {disabled} \
	CONFIG.PCW_MIO_0_SLEW {slow} \
	CONFIG.PCW_MIO_1_SLEW {slow} \
	CONFIG.PCW_MIO_2_SLEW {slow} \
	CONFIG.PCW_MIO_3_SLEW {slow} \
	CONFIG.PCW_MIO_4_SLEW {slow} \
	CONFIG.PCW_MIO_5_SLEW {slow} \
	CONFIG.PCW_MIO_6_SLEW {slow} \
	CONFIG.PCW_MIO_7_SLEW {slow} \
	CONFIG.PCW_MIO_8_SLEW {slow} \
	CONFIG.PCW_MIO_9_SLEW {slow} \
	CONFIG.PCW_MIO_10_SLEW {slow} \
	CONFIG.PCW_MIO_11_SLEW {slow} \
	CONFIG.PCW_MIO_12_SLEW {slow} \
	CONFIG.PCW_MIO_13_SLEW {slow} \
	CONFIG.PCW_MIO_14_SLEW {slow} \
	CONFIG.PCW_MIO_15_SLEW {slow} \
	CONFIG.PCW_MIO_16_SLEW {slow} \
	CONFIG.PCW_MIO_17_SLEW {slow} \
	CONFIG.PCW_MIO_18_SLEW {slow} \
	CONFIG.PCW_MIO_19_SLEW {slow} \
	CONFIG.PCW_MIO_20_SLEW {slow} \
	CONFIG.PCW_MIO_21_SLEW {slow} \
	CONFIG.PCW_MIO_22_SLEW {slow} \
	CONFIG.PCW_MIO_23_SLEW {slow} \
	CONFIG.PCW_MIO_24_SLEW {slow} \
	CONFIG.PCW_MIO_25_SLEW {slow} \
	CONFIG.PCW_MIO_26_SLEW {slow} \
	CONFIG.PCW_MIO_27_SLEW {slow} \
	CONFIG.PCW_MIO_28_SLEW {slow} \
	CONFIG.PCW_MIO_29_SLEW {slow} \
	CONFIG.PCW_MIO_30_SLEW {slow} \
	CONFIG.PCW_MIO_31_SLEW {slow} \
	CONFIG.PCW_MIO_32_SLEW {slow} \
	CONFIG.PCW_MIO_33_SLEW {slow} \
	CONFIG.PCW_MIO_34_SLEW {slow} \
	CONFIG.PCW_MIO_35_SLEW {slow} \
	CONFIG.PCW_MIO_36_SLEW {slow} \
	CONFIG.PCW_MIO_37_SLEW {slow} \
	CONFIG.PCW_MIO_38_SLEW {slow} \
	CONFIG.PCW_MIO_39_SLEW {slow} \
	CONFIG.PCW_MIO_40_SLEW {slow} \
	CONFIG.PCW_MIO_41_SLEW {slow} \
	CONFIG.PCW_MIO_42_SLEW {slow} \
	CONFIG.PCW_MIO_43_SLEW {slow} \
	CONFIG.PCW_MIO_44_SLEW {slow} \
	CONFIG.PCW_MIO_45_SLEW {slow} \
	CONFIG.PCW_MIO_46_SLEW {slow} \
	CONFIG.PCW_MIO_47_SLEW {slow} \
	CONFIG.PCW_MIO_48_SLEW {slow} \
	CONFIG.PCW_MIO_49_SLEW {slow} \
	CONFIG.PCW_MIO_50_SLEW {slow} \
	CONFIG.PCW_MIO_51_SLEW {slow} \
	CONFIG.PCW_MIO_52_SLEW {slow} \
	CONFIG.PCW_MIO_53_SLEW {slow} \
] [get_bd_cells processing_system7_0]

############################################################################
# Enable USB Reset last
############################################################################
set_property -dict [ list \
	CONFIG.PCW_USB0_RESET_ENABLE {1} \
] [get_bd_cells processing_system7_0]

############################################################################
# End PicoZed Presets 
############################################################################
}