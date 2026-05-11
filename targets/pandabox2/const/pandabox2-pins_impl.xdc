set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
# ----------------------------------------------------------------------------------
# Important! Do not remove this constraint!
# This property ensures that all unused pins are set to high impedance.
# If the constraint is removed, all unused pins have to be set to HiZ in the top level file.
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

# aux signals
set_property -dict {PACKAGE_PIN G13   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_RESET}]
#set_property -dict {PACKAGE_PIN F13   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_INT}]
set_property -dict {PACKAGE_PIN K14   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_OE}]

# IOs
set_property -dict {PACKAGE_PIN G10   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[0]}]
set_property -dict {PACKAGE_PIN F10   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[1]}]
set_property -dict {PACKAGE_PIN H12   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[2]}]
set_property -dict {PACKAGE_PIN G11   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[3]}]
set_property -dict {PACKAGE_PIN J12   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[4]}]
set_property -dict {PACKAGE_PIN H11   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[5]}]
set_property -dict {PACKAGE_PIN J11   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[6]}]
set_property -dict {PACKAGE_PIN J10   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_IO[7]}]

# DOs
set_property -dict {PACKAGE_PIN AG13  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[0]}]
set_property -dict {PACKAGE_PIN AH13  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[0]}]
set_property -dict {PACKAGE_PIN AF11  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[1]}]
set_property -dict {PACKAGE_PIN AG11  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[1]}]

# DIs
set_property -dict {PACKAGE_PIN AK13  IOSTANDARD LVDS} [get_ports {PANEL_F_DI_P[0]}]
set_property -dict {PACKAGE_PIN AK12  IOSTANDARD LVDS} [get_ports {PANEL_F_DI_N[0]}]
set_property -dict {PACKAGE_PIN AH7   IOSTANDARD LVDS} [get_ports {PANEL_F_DI_P[1]}]
set_property -dict {PACKAGE_PIN AJ7   IOSTANDARD LVDS} [get_ports {PANEL_F_DI_N[1]}]

# Is
set_property -dict {PACKAGE_PIN K13   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_I[0]}]
set_property -dict {PACKAGE_PIN K12   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_I[1]}]

# Os
set_property -dict {PACKAGE_PIN F12   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_O[0]}]
set_property -dict {PACKAGE_PIN F11   IOSTANDARD LVCMOS33} [get_ports {PANEL_F_O[1]}]

# LVDS
set_property -dict {PACKAGE_PIN AJ2   IOSTANDARD LVCMOS18} [get_ports {LVDS_DIR[0]}]
set_property -dict {PACKAGE_PIN AK2   IOSTANDARD LVCMOS18} [get_ports {LVDS_DIR[1]}]
set_property -dict {PACKAGE_PIN AK3   IOSTANDARD LVCMOS18} [get_ports {LVDS_D[0]}]
set_property -dict {PACKAGE_PIN AJ4   IOSTANDARD LVCMOS18} [get_ports {LVDS_D[1]}]
set_property -dict {PACKAGE_PIN AK4   IOSTANDARD LVCMOS18} [get_ports {LVDS_R[0]}]
set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_por LVDS_R[0]]
set_property -dict {PACKAGE_PIN AH4   IOSTANDARD LVCMOS18} [get_ports {LVDS_R[1]}]

# FMC
set_property -dict {PACKAGE_PIN U8    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][0]}]
set_property -dict {PACKAGE_PIN V8    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][0]}]
set_property -dict {PACKAGE_PIN W5    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][1]}]
set_property -dict {PACKAGE_PIN Y5    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][1]}]
set_property -dict {PACKAGE_PIN V4    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][2]}]
set_property -dict {PACKAGE_PIN W4    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][2]}]
set_property -dict {PACKAGE_PIN U5    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][3]}]
set_property -dict {PACKAGE_PIN U4    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][3]}]
set_property -dict {PACKAGE_PIN U7    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][4]}]
set_property -dict {PACKAGE_PIN U6    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][4]}]
set_property -dict {PACKAGE_PIN U9    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][5]}]
set_property -dict {PACKAGE_PIN V9    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][5]}]
set_property -dict {PACKAGE_PIN T11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][6]}]
set_property -dict {PACKAGE_PIN U10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][6]}]
set_property -dict {PACKAGE_PIN U11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][7]}]
set_property -dict {PACKAGE_PIN V11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][7]}]
set_property -dict {PACKAGE_PIN W11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][8]}]
set_property -dict {PACKAGE_PIN W10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][8]}]
set_property -dict {PACKAGE_PIN T1    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][9]}]
set_property -dict {PACKAGE_PIN U1    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][9]}]
set_property -dict {PACKAGE_PIN R10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][10]}]
set_property -dict {PACKAGE_PIN T10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][10]}]
set_property -dict {PACKAGE_PIN P11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][11]}]
set_property -dict {PACKAGE_PIN P10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][11]}]
set_property -dict {PACKAGE_PIN N10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][12]}]
set_property -dict {PACKAGE_PIN M10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][12]}]
set_property -dict {PACKAGE_PIN N12   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][13]}]
set_property -dict {PACKAGE_PIN M12   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][13]}]
set_property -dict {PACKAGE_PIN Y9    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][14]}]
set_property -dict {PACKAGE_PIN Y8    IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][14]}]
set_property -dict {PACKAGE_PIN L12   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][15]}]
set_property -dict {PACKAGE_PIN L11   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][15]}]
set_property -dict {PACKAGE_PIN L10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][16]}]
set_property -dict {PACKAGE_PIN K10   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][16]}]
set_property -dict {PACKAGE_PIN AB6   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][17]}]
set_property -dict {PACKAGE_PIN AB5   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][17]}]
set_property -dict {PACKAGE_PIN AB8   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][18]}]
set_property -dict {PACKAGE_PIN AC8   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][18]}]
set_property -dict {PACKAGE_PIN AA8   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][19]}]
set_property -dict {PACKAGE_PIN AA7   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][19]}]
set_property -dict {PACKAGE_PIN AB9   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][20]}]
set_property -dict {PACKAGE_PIN AC9   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][20]}]
set_property -dict {PACKAGE_PIN AD9   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][21]}]
set_property -dict {PACKAGE_PIN AE9   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][21]}]
set_property -dict {PACKAGE_PIN AD10  IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][22]}]
set_property -dict {PACKAGE_PIN AE10  IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][22]}]
set_property -dict {PACKAGE_PIN AD4   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][23]}]
set_property -dict {PACKAGE_PIN AE4   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][23]}]
set_property -dict {PACKAGE_PIN AD5   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][24]}]
set_property -dict {PACKAGE_PIN AE5   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][24]}]
set_property -dict {PACKAGE_PIN AB4   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][25]}]
set_property -dict {PACKAGE_PIN AC4   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][25]}]
set_property -dict {PACKAGE_PIN AA6   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][26]}]
set_property -dict {PACKAGE_PIN AA5   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][26]}]
set_property -dict {PACKAGE_PIN AE3   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][27]}]
set_property -dict {PACKAGE_PIN AE2   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][27]}]
set_property -dict {PACKAGE_PIN AB11  IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][28]}]
set_property -dict {PACKAGE_PIN AB10  IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][28]}]
set_property -dict {PACKAGE_PIN AC2   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][29]}]
set_property -dict {PACKAGE_PIN AD2   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][29]}]
set_property -dict {PACKAGE_PIN AC1   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][30]}]
set_property -dict {PACKAGE_PIN AD1   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][30]}]
set_property -dict {PACKAGE_PIN AB3   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][31]}]
set_property -dict {PACKAGE_PIN AC3   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][31]}]
set_property -dict {PACKAGE_PIN AA3   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][32]}]
set_property -dict {PACKAGE_PIN AA2   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][32]}]
set_property -dict {PACKAGE_PIN AA1   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_P[0][33]}]
set_property -dict {PACKAGE_PIN AB1   IOSTANDARD LVCMOS18} [get_ports {FMC_LA_N[0][33]}]
set_property -dict {PACKAGE_PIN W7    IOSTANDARD LVCMOS18} [get_ports {FMC_CLK0_M2C_P[0]}]
set_property -dict {PACKAGE_PIN W6    IOSTANDARD LVCMOS18} [get_ports {FMC_CLK0_M2C_N[0]}]
set_property -dict {PACKAGE_PIN AC6   IOSTANDARD LVCMOS18} [get_ports {FMC_CLK1_M2C_P[0]}]
set_property -dict {PACKAGE_PIN AD6   IOSTANDARD LVCMOS18} [get_ports {FMC_CLK1_M2C_N[0]}]
set_property -dict {PACKAGE_PIN Y4    IOSTANDARD LVCMOS18} [get_ports {FMC_PRSNT_L[0]}]
# set_property -dict {PACKAGE_PIN Y3    IOSTANDARD LVCMOS18  } [get_ports {FMC_PRSNT_H}]
# set_property -dict {PACKAGE_PIN AF10  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK_DIR}]
# set_property -dict {PACKAGE_PIN AE13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK2_BIDIR_P}]
# set_property -dict {PACKAGE_PIN AF13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK2_BIDIR_N}]
# set_property -dict {PACKAGE_PIN AB13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK3_BIDIR_P}]
# set_property -dict {PACKAGE_PIN AC13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK3_BIDIR_N}]

# Encoders
set_property -dict {PACKAGE_PIN A12   IOSTANDARD LVCMOS33} [get_ports {AENC[1]}]
set_property -dict {PACKAGE_PIN B11   IOSTANDARD LVCMOS33} [get_ports {AENC[2]}]
set_property -dict {PACKAGE_PIN D11   IOSTANDARD LVCMOS33} [get_ports {AENC[3]}]
set_property -dict {PACKAGE_PIN D10   IOSTANDARD LVCMOS33} [get_ports {AENC[4]}]
set_property -dict {PACKAGE_PIN E14   IOSTANDARD LVCMOS33} [get_ports {AENC[5]}]
set_property -dict {PACKAGE_PIN C13   IOSTANDARD LVCMOS33} [get_ports {AENC[6]}]
set_property -dict {PACKAGE_PIN B14   IOSTANDARD LVCMOS33} [get_ports {AENC[7]}]
set_property -dict {PACKAGE_PIN A13   IOSTANDARD LVCMOS33} [get_ports {AENC[8]}]
set_property -dict {PACKAGE_PIN A11   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[1]}]
set_property -dict {PACKAGE_PIN B10   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[2]}]
set_property -dict {PACKAGE_PIN C11   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[3]}]
set_property -dict {PACKAGE_PIN E12   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[4]}]
set_property -dict {PACKAGE_PIN E13   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[5]}]
set_property -dict {PACKAGE_PIN B15   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[6]}]
set_property -dict {PACKAGE_PIN A14   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[7]}]
set_property -dict {PACKAGE_PIN H14   IOSTANDARD LVCMOS33} [get_ports {B_CLKENC[8]}]
set_property -dict {PACKAGE_PIN C12   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[1]}]
set_property -dict {PACKAGE_PIN A10   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[2]}]
set_property -dict {PACKAGE_PIN E10   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[3]}]
set_property -dict {PACKAGE_PIN D12   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[4]}]
set_property -dict {PACKAGE_PIN C14   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[5]}]
set_property -dict {PACKAGE_PIN A15   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[6]}]
set_property -dict {PACKAGE_PIN B13   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[7]}]
set_property -dict {PACKAGE_PIN H13   IOSTANDARD LVCMOS33} [get_ports {Z_DATAENC[8]}]
set_property -dict {PACKAGE_PIN AK9   IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[0]}]
set_property -dict {PACKAGE_PIN AK8   IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[1]}]
set_property -dict {PACKAGE_PIN AJ10  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[2]}]
set_property -dict {PACKAGE_PIN AK10  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[3]}]
set_property -dict {PACKAGE_PIN AH12  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[4]}]
set_property -dict {PACKAGE_PIN AJ12  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[5]}]
set_property -dict {PACKAGE_PIN AJ11  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[6]}]
set_property -dict {PACKAGE_PIN AK11  IOSTANDARD LVCMOS18} [get_ports {PANEL_R_CTRL[7]}]

# Extra IOs, still not assigned in design
# Before: PT46 and PT47
set_property -dict {PACKAGE_PIN AG4   IOSTANDARD LVCMOS18} [get_ports {I2C_1_SCK}]
set_property -dict {PACKAGE_PIN AJ1   IOSTANDARD LVCMOS18} [get_ports {I2C_1_SDA}]

# Before: PT51 and PT52
set_property -dict {PACKAGE_PIN AF8  IOSTANDARD LVCMOS18} [get_ports {PROP_IO[0]}]
set_property -dict {PACKAGE_PIN AF7  IOSTANDARD LVCMOS18} [get_ports {PROP_IO[1]}]

# Before: PT48 and PT49
set_property -dict {PACKAGE_PIN AH11  IOSTANDARD LVCMOS18} [get_ports {PROP_IO_DIR[0]}]
set_property -dict {PACKAGE_PIN AG9  IOSTANDARD LVCMOS18} [get_ports {PROP_IO_DIR[1]}]

# Before: PT50 and PT53
set_property -dict {PACKAGE_PIN AG10  IOSTANDARD LVCMOS18} [get_ports {PROP_IO_TERM[0]}]
set_property -dict {PACKAGE_PIN AG1  IOSTANDARD LVCMOS18} [get_ports {PROP_IO_TERM[1]}]

# SFPs
set_property PACKAGE_PIN E8 [get_ports {MGT_REFCLK1_IN0_P}]
set_property PACKAGE_PIN E7 [get_ports {MGT_REFCLK1_IN0_N}]
set_property -dict {PACKAGE_PIN AF2   IOSTANDARD LVCMOS18} [get_ports {SFP_TX_DISABLE[0]}]
set_property -dict {PACKAGE_PIN AF1   IOSTANDARD LVCMOS18} [get_ports {SFP_RX_LOS[0]}]
set_property -dict {PACKAGE_PIN AJ5   IOSTANDARD LVCMOS18} [get_ports {SFP_TX_DISABLE[1]}]
set_property -dict {PACKAGE_PIN AK5   IOSTANDARD LVCMOS18} [get_ports {SFP_RX_LOS[1]}]
set_property -dict {PACKAGE_PIN AK7   IOSTANDARD LVCMOS18} [get_ports {SFP_TX_DISABLE[2]}]
set_property -dict {PACKAGE_PIN AK6   IOSTANDARD LVCMOS18} [get_ports {SFP_RX_LOS[2]}]
set_property -dict {PACKAGE_PIN AF6   IOSTANDARD LVCMOS18} [get_ports {SFP_TX_DISABLE[3]}]
set_property -dict {PACKAGE_PIN AF5   IOSTANDARD LVCMOS18} [get_ports {SFP_RX_LOS[3]}]

set SFP1_LOC        GTHE4_CHANNEL_X1Y12
set SFP2_LOC        GTHE4_CHANNEL_X1Y13
set SFP3_LOC        GTHE4_CHANNEL_X1Y14
set SFP4_LOC        GTHE4_CHANNEL_X1Y15
set FMC_MGT1_LOC    GTHE4_CHANNEL_X1Y8
set FMC_MGT2_LOC    GTHE4_CHANNEL_X1Y9
set FMC_MGT3_LOC    GTHE4_CHANNEL_X1Y10
set FMC_MGT4_LOC    GTHE4_CHANNEL_X1Y11
set FMC_MGT5_LOC    GTHE4_CHANNEL_X1Y4
set FMC_MGT6_LOC    GTHE4_CHANNEL_X1Y5
set FMC_MGT7_LOC    GTHE4_CHANNEL_X1Y6
set FMC_MGT8_LOC    GTHE4_CHANNEL_X1Y7
set FMC_MGT9_LOC    GTHE4_CHANNEL_X0Y4
set FMC_MGT10_LOC   GTHE4_CHANNEL_X0Y5
set FMC_MGT11_LOC   GTHE4_CHANNEL_X0Y6
set FMC_MGT12_LOC   GTHE4_CHANNEL_X0Y7

