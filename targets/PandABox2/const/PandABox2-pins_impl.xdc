set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
 
# ----------------------------------------------------------------------------------
# Important! Do not remove this constraint!
# This property ensures that all unused pins are set to high impedance.
# If the constraint is removed, all unused pins have to be set to HiZ in the top level file.
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
# ----------------------------------------------------------------------------------

set_property -dict {PACKAGE_PIN A12   IOSTANDARD LVCMOS33  } [get_ports {AENC1}]
set_property -dict {PACKAGE_PIN A11   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC1}]
set_property -dict {PACKAGE_PIN C12   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC1}]
set_property -dict {PACKAGE_PIN B11   IOSTANDARD LVCMOS33  } [get_ports {AENC2}]
set_property -dict {PACKAGE_PIN B10   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC2}]
set_property -dict {PACKAGE_PIN A10   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC2}]
set_property -dict {PACKAGE_PIN D11   IOSTANDARD LVCMOS33  } [get_ports {AENC3}]
set_property -dict {PACKAGE_PIN C11   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC3}]
set_property -dict {PACKAGE_PIN E10   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC3}]
set_property -dict {PACKAGE_PIN D10   IOSTANDARD LVCMOS33  } [get_ports {AENC4}]
set_property -dict {PACKAGE_PIN E12   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC4}]
set_property -dict {PACKAGE_PIN D12   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC4}]
set_property -dict {PACKAGE_PIN E14   IOSTANDARD LVCMOS33  } [get_ports {AENC5}]
set_property -dict {PACKAGE_PIN E13   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC5}]
set_property -dict {PACKAGE_PIN C14   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC5}]
set_property -dict {PACKAGE_PIN C13   IOSTANDARD LVCMOS33  } [get_ports {AENC6}]
set_property -dict {PACKAGE_PIN B15   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC6}]
set_property -dict {PACKAGE_PIN A15   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC6}]
set_property -dict {PACKAGE_PIN B14   IOSTANDARD LVCMOS33  } [get_ports {AENC7}]
set_property -dict {PACKAGE_PIN A14   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC7}]
set_property -dict {PACKAGE_PIN B13   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC7}]
set_property -dict {PACKAGE_PIN A13   IOSTANDARD LVCMOS33  } [get_ports {AENC8}]
set_property -dict {PACKAGE_PIN H14   IOSTANDARD LVCMOS33  } [get_ports {B_CLKENC8}]
set_property -dict {PACKAGE_PIN H13   IOSTANDARD LVCMOS33  } [get_ports {Z_DATAENC8}]

set_property -dict {PACKAGE_PIN D15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_0}]
set_property -dict {PACKAGE_PIN D14   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_1}]
set_property -dict {PACKAGE_PIN G10   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_0}]
set_property -dict {PACKAGE_PIN F10   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_1}]
set_property -dict {PACKAGE_PIN H12   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_2}]
set_property -dict {PACKAGE_PIN G11   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_3}]
set_property -dict {PACKAGE_PIN J12   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_4}]
set_property -dict {PACKAGE_PIN H11   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_5}]
set_property -dict {PACKAGE_PIN J11   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_6}]
set_property -dict {PACKAGE_PIN J10   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_IO_7}]
set_property -dict {PACKAGE_PIN K13   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_I_0}]
set_property -dict {PACKAGE_PIN K12   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_I_1}]
set_property -dict {PACKAGE_PIN F12   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_O_0}]
set_property -dict {PACKAGE_PIN F11   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_O_1}]
set_property -dict {PACKAGE_PIN G13   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_RESET}]
set_property -dict {PACKAGE_PIN F13   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_INT}]
set_property -dict {PACKAGE_PIN K14   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_OE}]
set_property -dict {PACKAGE_PIN J14   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_2}]
set_property -dict {PACKAGE_PIN K15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_3}]
set_property -dict {PACKAGE_PIN J15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_4}]
set_property -dict {PACKAGE_PIN G15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_5}]
set_property -dict {PACKAGE_PIN G14   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_6}]
set_property -dict {PACKAGE_PIN F15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_7}]
set_property -dict {PACKAGE_PIN E15   IOSTANDARD LVCMOS33  } [get_ports {PANEL_F_SPARE_8}]
set_property -dict {PACKAGE_PIN AG4   IOSTANDARD LVCMOS18  } [get_ports {PT46}]
set_property -dict {PACKAGE_PIN AJ1   IOSTANDARD LVCMOS18  } [get_ports {PT47}]
set_property -dict {PACKAGE_PIN AH11  IOSTANDARD LVCMOS18  } [get_ports {PT48}]
set_property -dict {PACKAGE_PIN AG9   IOSTANDARD LVCMOS18  } [get_ports {PT50}]

set_property PACKAGE_PIN E8    [get_ports {MGT_REFCLK1_IN0_P}] # GTH
set_property PACKAGE_PIN E7    [get_ports {MGT_REFCLK1_IN0_N}] # GTH
set_property PACKAGE_PIN D6    [get_ports {SFP1_TX_P}] # GTH
set_property PACKAGE_PIN D5    [get_ports {SFP1_TX_N}] # GTH
# set_property PACKAGE_PIN C8    [get_ports {SFP2_TX_P}] # GTH
# set_property PACKAGE_PIN C7    [get_ports {SFP2_TX_N}] # GTH
set_property -dict {PACKAGE_PIN W7    IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK0_M2C_P}]
set_property -dict {PACKAGE_PIN W6    IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK0_M2C_N}]
# set_property PACKAGE_PIN B6    [get_ports {SFP3_TX_P}] # GTH
# set_property PACKAGE_PIN B5    [get_ports {SFP3_TX_N}] # GTH
# set_property PACKAGE_PIN A8    [get_ports {SFP4_TX_P}] # GTH
# set_property PACKAGE_PIN A7    [get_ports {SFP4_TX_N}] # GTH

set_property -dict {PACKAGE_PIN T1    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA_P}]
set_property -dict {PACKAGE_PIN U1    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA_N}]
set_property -dict {PACKAGE_PIN W5    IOSTANDARD LVCMOS18  } [get_ports {LA_P_1}]
set_property -dict {PACKAGE_PIN Y5    IOSTANDARD LVCMOS18  } [get_ports {LA_N_1}]
set_property -dict {PACKAGE_PIN V4    IOSTANDARD LVCMOS18  } [get_ports {LA_P_2}]
set_property -dict {PACKAGE_PIN W4    IOSTANDARD LVCMOS18  } [get_ports {LA_N_2}]
set_property -dict {PACKAGE_PIN U5    IOSTANDARD LVCMOS18  } [get_ports {LA_P_3}]
set_property -dict {PACKAGE_PIN U4    IOSTANDARD LVCMOS18  } [get_ports {LA_N_3}]
set_property -dict {PACKAGE_PIN U7    IOSTANDARD LVCMOS18  } [get_ports {LA_P_4}]
set_property -dict {PACKAGE_PIN U6    IOSTANDARD LVCMOS18  } [get_ports {LA_N_4}]
set_property -dict {PACKAGE_PIN U9    IOSTANDARD LVCMOS18  } [get_ports {LA_P_5}]
set_property -dict {PACKAGE_PIN V9    IOSTANDARD LVCMOS18  } [get_ports {LA_N_5}]
set_property -dict {PACKAGE_PIN T11   IOSTANDARD LVCMOS18  } [get_ports {LA_P_6}]
set_property -dict {PACKAGE_PIN U10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_6}]
set_property -dict {PACKAGE_PIN U11   IOSTANDARD LVCMOS18  } [get_ports {LA_P_7}]
set_property -dict {PACKAGE_PIN V11   IOSTANDARD LVCMOS18  } [get_ports {LA_N_7}]
set_property -dict {PACKAGE_PIN W11   IOSTANDARD LVCMOS18  } [get_ports {LA_P_8}]
set_property -dict {PACKAGE_PIN W10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_8}]
set_property -dict {PACKAGE_PIN U8    IOSTANDARD LVCMOS18  } [get_ports {LA_P_0}]
set_property -dict {PACKAGE_PIN V8    IOSTANDARD LVCMOS18  } [get_ports {LA_N_0}]
set_property -dict {PACKAGE_PIN R10   IOSTANDARD LVCMOS18  } [get_ports {LA_P_10}]
set_property -dict {PACKAGE_PIN T10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_10}]
set_property -dict {PACKAGE_PIN P11   IOSTANDARD LVCMOS18  } [get_ports {LA_P_11}]
set_property -dict {PACKAGE_PIN P10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_11}]
set_property -dict {PACKAGE_PIN N10   IOSTANDARD LVCMOS18  } [get_ports {LA_P_12}]
set_property -dict {PACKAGE_PIN M10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_12}]
set_property -dict {PACKAGE_PIN N12   IOSTANDARD LVCMOS18  } [get_ports {LA_P_13}]
set_property -dict {PACKAGE_PIN M12   IOSTANDARD LVCMOS18  } [get_ports {LA_N_13}]
set_property -dict {PACKAGE_PIN Y9    IOSTANDARD LVCMOS18  } [get_ports {LA_P_14}]
set_property -dict {PACKAGE_PIN Y8    IOSTANDARD LVCMOS18  } [get_ports {LA_N_14}]
set_property -dict {PACKAGE_PIN L12   IOSTANDARD LVCMOS18  } [get_ports {LA_P_15}]
set_property -dict {PACKAGE_PIN L11   IOSTANDARD LVCMOS18  } [get_ports {LA_N_15}]
set_property -dict {PACKAGE_PIN L10   IOSTANDARD LVCMOS18  } [get_ports {LA_P_16}]
set_property -dict {PACKAGE_PIN K10   IOSTANDARD LVCMOS18  } [get_ports {LA_N_16}]

set_property PACKAGE_PIN G8    [get_ports {MGT_WR_IN0_P}] # GTH
set_property PACKAGE_PIN G7    [get_ports {MGT_WR_IN0_N}] # GTH
set_property PACKAGE_PIN D2    [get_ports {SFP1_RX_P}] # GTH
set_property PACKAGE_PIN D1    [get_ports {SFP1_RX_N}] # GTH
# set_property PACKAGE_PIN C4    [get_ports {SFP2_RX_P}] # GTH
# set_property PACKAGE_PIN C3    [get_ports {SFP2_RX_N}] # GTH
# set_property PACKAGE_PIN B2    [get_ports {SFP3_RX_P}] # GTH
# set_property PACKAGE_PIN B1    [get_ports {SFP3_RX_N}] # GTH
# set_property PACKAGE_PIN A4    [get_ports {SFP4_RX_P}] # GTH
# set_property PACKAGE_PIN A3    [get_ports {SFP4_RX_N}] # GTH

set_property -dict {PACKAGE_PIN AB11  IOSTANDARD LVCMOS18  } [get_ports {LA_P_28}]
set_property -dict {PACKAGE_PIN AB10  IOSTANDARD LVCMOS18  } [get_ports {LA_N_28}]
set_property -dict {PACKAGE_PIN AB8   IOSTANDARD LVCMOS18  } [get_ports {LA_P_18}]
set_property -dict {PACKAGE_PIN AC8   IOSTANDARD LVCMOS18  } [get_ports {LA_N_18}]
set_property -dict {PACKAGE_PIN AA8   IOSTANDARD LVCMOS18  } [get_ports {LA_P_19}]
set_property -dict {PACKAGE_PIN AA7   IOSTANDARD LVCMOS18  } [get_ports {LA_N_19}]
set_property -dict {PACKAGE_PIN AB9   IOSTANDARD LVCMOS18  } [get_ports {LA_P_20}]
set_property -dict {PACKAGE_PIN AC9   IOSTANDARD LVCMOS18  } [get_ports {LA_N_20}]
set_property -dict {PACKAGE_PIN AD9   IOSTANDARD LVCMOS18  } [get_ports {LA_P_21}]
set_property -dict {PACKAGE_PIN AE9   IOSTANDARD LVCMOS18  } [get_ports {LA_N_21}]
set_property -dict {PACKAGE_PIN AD10  IOSTANDARD LVCMOS18  } [get_ports {LA_P_22}]
set_property -dict {PACKAGE_PIN AE10  IOSTANDARD LVCMOS18  } [get_ports {LA_N_22}]
set_property -dict {PACKAGE_PIN AD4   IOSTANDARD LVCMOS18  } [get_ports {LA_P_23}]
set_property -dict {PACKAGE_PIN AE4   IOSTANDARD LVCMOS18  } [get_ports {LA_N_23}]
set_property -dict {PACKAGE_PIN AD5   IOSTANDARD LVCMOS18  } [get_ports {LA_P_24}]
set_property -dict {PACKAGE_PIN AE5   IOSTANDARD LVCMOS18  } [get_ports {LA_N_24}]
set_property -dict {PACKAGE_PIN AB4   IOSTANDARD LVCMOS18  } [get_ports {LA_P_25}]
set_property -dict {PACKAGE_PIN AC4   IOSTANDARD LVCMOS18  } [get_ports {LA_N_25}]
set_property -dict {PACKAGE_PIN AA6   IOSTANDARD LVCMOS18  } [get_ports {LA_P_26}]
set_property -dict {PACKAGE_PIN AA5   IOSTANDARD LVCMOS18  } [get_ports {LA_N_26}]
set_property -dict {PACKAGE_PIN AE3   IOSTANDARD LVCMOS18  } [get_ports {LA_P_27}]
set_property -dict {PACKAGE_PIN AE2   IOSTANDARD LVCMOS18  } [get_ports {LA_N_27}]
set_property -dict {PACKAGE_PIN AB6   IOSTANDARD LVCMOS18  } [get_ports {LA_P_17}]
set_property -dict {PACKAGE_PIN AB5   IOSTANDARD LVCMOS18  } [get_ports {LA_N_17}]
set_property -dict {PACKAGE_PIN AC2   IOSTANDARD LVCMOS18  } [get_ports {LA_P_29}]
set_property -dict {PACKAGE_PIN AD2   IOSTANDARD LVCMOS18  } [get_ports {LA_N_29}]
set_property -dict {PACKAGE_PIN AC1   IOSTANDARD LVCMOS18  } [get_ports {LA_P_30}]
set_property -dict {PACKAGE_PIN AD1   IOSTANDARD LVCMOS18  } [get_ports {LA_P_30}]
set_property -dict {PACKAGE_PIN AB3   IOSTANDARD LVCMOS18  } [get_ports {LA_P_31}]
set_property -dict {PACKAGE_PIN AC3   IOSTANDARD LVCMOS18  } [get_ports {LA_N_31}]
set_property -dict {PACKAGE_PIN AC6   IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK1_M2C_P}]
set_property -dict {PACKAGE_PIN AD6   IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK1_M2C_N}]
set_property -dict {PACKAGE_PIN AA1   IOSTANDARD LVCMOS18  } [get_ports {LA_P_33}]
set_property -dict {PACKAGE_PIN AB1   IOSTANDARD LVCMOS18  } [get_ports {LA_N_33}]
set_property -dict {PACKAGE_PIN AA3   IOSTANDARD LVCMOS18  } [get_ports {LA_P_32}]
set_property -dict {PACKAGE_PIN AA2   IOSTANDARD LVCMOS18  } [get_ports {LA_N_32}]

set_property PACKAGE_PIN J8    [get_ports {MGT_REFCLK1_IN1_P}] # GTH
set_property PACKAGE_PIN J7    [get_ports {MGT_REFCLK1_IN1_N}] # GTH
set_property PACKAGE_PIN N8    [get_ports {MGT_REFCLK1_IN2_P}] # GTH
set_property PACKAGE_PIN N7    [get_ports {MGT_REFCLK1_IN2_N}] # GTH
set_property PACKAGE_PIN J4    [get_ports {FMC_DP_C2M_P}] # GTH
set_property PACKAGE_PIN J3    [get_ports {FMC_DP_C2M_N}] # GTH
# set_property PACKAGE_PIN H6    [get_ports {FMC_DP_C2M_P1}] # GTH
# set_property PACKAGE_PIN H5    [get_ports {FMC_DP_C2M_N1}] # GTH
# set_property PACKAGE_PIN F6    [get_ports {FMC_DP_C2M_P2}] # GTH
# set_property PACKAGE_PIN F5    [get_ports {FMC_DP_C2M_N2}] # GTH
# set_property PACKAGE_PIN E4    [get_ports {FMC_DP_C2M_P3}] # GTH
# set_property PACKAGE_PIN E3    [get_ports {FMC_DP_C2M_N3}] # GTH
# set_property PACKAGE_PIN P6    [get_ports {FMC_DP_C2M_P4}] # GTH
# set_property PACKAGE_PIN P5    [get_ports {FMC_DP_C2M_N4}] # GTH
# set_property PACKAGE_PIN N4    [get_ports {FMC_DP_C2M_P5}] # GTH
# set_property PACKAGE_PIN N3    [get_ports {FMC_DP_C2M_N5}] # GTH
# set_property PACKAGE_PIN M6    [get_ports {FMC_DP_C2M_P6}] # GTH
# set_property PACKAGE_PIN M5    [get_ports {FMC_DP_C2M_N6}] # GTH
# set_property PACKAGE_PIN K6    [get_ports {FMC_DP_C2M_P7}] # GTH
# set_property PACKAGE_PIN K5    [get_ports {FMC_DP_C2M_N7}] # GTH
set_property PACKAGE_PIN F25   [get_ports {MGT_REFCLK0_IN1_P}] # GTH
set_property PACKAGE_PIN F26   [get_ports {MGT_REFCLK0_IN1_N}] # GTH
# set_property PACKAGE_PIN G27   [get_ports {FMC_DP_C2M_P8}] # GTH
# set_property PACKAGE_PIN G28   [get_ports {FMC_DP_C2M_N8}] # GTH
# set_property PACKAGE_PIN E27   [get_ports {FMC_DP_C2M_P9}] # GTH
# set_property PACKAGE_PIN E28   [get_ports {FMC_DP_C2M_N9}] # GTH
# set_property PACKAGE_PIN C27   [get_ports {FMC_DP_C2M_P10}] # GTH
# set_property PACKAGE_PIN C28   [get_ports {FMC_DP_C2M_N10}] # GTH
# set_property PACKAGE_PIN A27   [get_ports {FMC_DP_C2M_P11}] # GTH
# set_property PACKAGE_PIN A28   [get_ports {FMC_DP_C2M_P11}] # GTH

set_property -dict {PACKAGE_PIN Y2    IOSTANDARD LVDS      } [get_ports {EXT_CLK_P}]
set_property -dict {PACKAGE_PIN Y1    IOSTANDARD LVDS      } [get_ports {EXT_CLK_N}]
set_property -dict {PACKAGE_PIN Y4    IOSTANDARD LVCMOS18  } [get_ports {FMC_PRSNT_L}]
set_property -dict {PACKAGE_PIN Y3    IOSTANDARD LVCMOS18  } [get_ports {FMC_PRSNT_H}]
set_property -dict {PACKAGE_PIN AF10  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK_DIR}]
set_property -dict {PACKAGE_PIN AG10  IOSTANDARD LVCMOS18  } [get_ports {PT_50}]
set_property -dict {PACKAGE_PIN AF8   IOSTANDARD LVCMOS18  } [get_ports {PT_51}]
set_property -dict {PACKAGE_PIN AF7   IOSTANDARD LVCMOS18  } [get_ports {PT_52}]
set_property -dict {PACKAGE_PIN AG8   IOSTANDARD LVCMOS18  } [get_ports {FAN_TACH0}]
set_property -dict {PACKAGE_PIN AH8   IOSTANDARD LVCMOS18  } [get_ports {FAN_TACH1}]
set_property -dict {PACKAGE_PIN AH9   IOSTANDARD LVCMOS18  } [get_ports {FAN_TACH2}]
set_property -dict {PACKAGE_PIN AJ9   IOSTANDARD LVCMOS18  } [get_ports {FAN_TACH3}]
set_property -dict {PACKAGE_PIN AK9   IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL0}]
set_property -dict {PACKAGE_PIN AK8   IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL1}]
set_property -dict {PACKAGE_PIN AJ10  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL2}]
set_property -dict {PACKAGE_PIN AK10  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL3}]
set_property -dict {PACKAGE_PIN AH12  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL4}]
set_property -dict {PACKAGE_PIN AJ12  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL5}]
set_property -dict {PACKAGE_PIN AJ11  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL6}]
set_property -dict {PACKAGE_PIN AK11  IOSTANDARD LVCMOS18  } [get_ports {PANEL_R_CTRL7}]
set_property -dict {PACKAGE_PIN AK13  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DI_P_0}]
set_property -dict {PACKAGE_PIN AK12  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DI_N_0}]
set_property -dict {PACKAGE_PIN AH7   IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DI_P_1}]
set_property -dict {PACKAGE_PIN AJ7   IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DI_N_1}]
set_property -dict {PACKAGE_PIN AG13  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DO_P_0}]
set_property -dict {PACKAGE_PIN AH13  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DO_N_0}]
set_property -dict {PACKAGE_PIN AF11  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DO_P_1}]
set_property -dict {PACKAGE_PIN AG11  IOSTANDARD LVCMOS18  } [get_ports {PANEL_F_DO_N_1}]

set_property PACKAGE_PIN L8    [get_ports {MGT_REFCLK0_IN2_P}] # GTH
set_property PACKAGE_PIN L7    [get_ports {MGT_REFCLK0_IN2_N}] # GTH
set_property PACKAGE_PIN R8    [get_ports {MGT_REFCLK0_IN3_P}] # GTH
set_property PACKAGE_PIN R7    [get_ports {MGT_REFCLK0_IN3_N}] # GTH
set_property PACKAGE_PIN K2    [get_ports {FMC_DP_M2C_P}] # GTH
set_property PACKAGE_PIN K1    [get_ports {FMC_DP_M2C_N}] # GTH
# set_property PACKAGE_PIN H2    [get_ports {FMC_DP_M2C_P1}] # GTH
# set_property PACKAGE_PIN H1    [get_ports {FMC_DP_M2C_N1}] # GTH
# set_property PACKAGE_PIN G4    [get_ports {FMC_DP_M2C_P2}] # GTH
# set_property PACKAGE_PIN G3    [get_ports {FMC_DP_M2C_N2}] # GTH
# set_property PACKAGE_PIN F2    [get_ports {FMC_DP_M2C_P3}] # GTH
# set_property PACKAGE_PIN F1    [get_ports {FMC_DP_M2C_N3}] # GTH
# set_property PACKAGE_PIN R4    [get_ports {FMC_DP_M2C_P4}] # GTH
# set_property PACKAGE_PIN R3    [get_ports {FMC_DP_M2C_N4}] # GTH
# set_property PACKAGE_PIN P2    [get_ports {FMC_DP_M2C_P5}] # GTH
# set_property PACKAGE_PIN P1    [get_ports {FMC_DP_M2C_N5}] # GTH
# set_property PACKAGE_PIN M2    [get_ports {FMC_DP_M2C_P6}] # GTH
# set_property PACKAGE_PIN M1    [get_ports {FMC_DP_M2C_N6}] # GTH
# set_property PACKAGE_PIN L4    [get_ports {FMC_DP_M2C_P7}] # GTH
# set_property PACKAGE_PIN L3    [get_ports {FMC_DP_M2C_N7}] # GTH
set_property PACKAGE_PIN D25   [get_ports {MGT_REFCLK1_IN3_P}] # GTH
set_property PACKAGE_PIN D26   [get_ports {MGT_REFCLK1_IN3_N}] # GTH
# set_property PACKAGE_PIN H29   [get_ports {FMC_DP_M2C_P8}] # GTH
# set_property PACKAGE_PIN H30   [get_ports {FMC_DP_M2C_N8}] # GTH
# set_property PACKAGE_PIN F29   [get_ports {FMC_DP_M2C_P9}] # GTH
# set_property PACKAGE_PIN F30   [get_ports {FMC_DP_M2C_N9}] # GTH
# set_property PACKAGE_PIN D29   [get_ports {FMC_DP_M2C_P10}] # GTH
# set_property PACKAGE_PIN D30   [get_ports {FMC_DP_M2C_N10}] # GTH
# set_property PACKAGE_PIN B29   [get_ports {FMC_DP_M2C_P11}] # GTH
# set_property PACKAGE_PIN B30   [get_ports {FMC_DP_M2C_N11}] # GTH
set_property -dict {PACKAGE_PIN AE13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK2_BIDIR_P}]
set_property -dict {PACKAGE_PIN AF13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK2_BIDIR_N}]
set_property -dict {PACKAGE_PIN AB13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK3_BIDIR_P}]
set_property -dict {PACKAGE_PIN AC13  IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK3_BIDIR_N}]
set_property -dict {PACKAGE_PIN AF2   IOSTANDARD LVCMOS18  } [get_ports {SFP1_TX_DISABLE}]
set_property -dict {PACKAGE_PIN AF1   IOSTANDARD LVCMOS18  } [get_ports {SFP1_RX_LOS}]
set_property -dict {PACKAGE_PIN AF3   IOSTANDARD LVCMOS18  } [get_ports {PLL25DAC_SCLK}]
set_property -dict {PACKAGE_PIN AG3   IOSTANDARD LVCMOS18  } [get_ports {PLL25DAC_DIN}]
set_property -dict {PACKAGE_PIN AG1   IOSTANDARD LVCMOS18  } [get_ports {PT53}]
set_property -dict {PACKAGE_PIN AH1   IOSTANDARD LVCMOS18  } [get_ports {PLL25DAC_2_SYNC}]
set_property -dict {PACKAGE_PIN AG6   IOSTANDARD LVCMOS18  } [get_ports {CLK20_VCXO}]
set_property -dict {PACKAGE_PIN AG5   IOSTANDARD LVCMOS18  } [get_ports {PLL25DAC_1_SYNC}]
set_property -dict {PACKAGE_PIN AJ2   IOSTANDARD LVCMOS18  } [get_ports {LVDS0_DIR}]
set_property -dict {PACKAGE_PIN AK2   IOSTANDARD LVCMOS18  } [get_ports {LVDS1_DIR}]
set_property -dict {PACKAGE_PIN AH3   IOSTANDARD LVCMOS18  } [get_ports {CLK_MUX0_SEL}]
set_property -dict {PACKAGE_PIN AH2   IOSTANDARD LVCMOS18  } [get_ports {CLK_MUX1_SEL}]
set_property -dict {PACKAGE_PIN AK4   IOSTANDARD LVCMOS18  } [get_ports {LVDS0_R}]
set_property -dict {PACKAGE_PIN AK3   IOSTANDARD LVCMOS18  } [get_ports {LVDS0_D}]
set_property -dict {PACKAGE_PIN AH4   IOSTANDARD LVCMOS18  } [get_ports {LVDS1_R}]
set_property -dict {PACKAGE_PIN AJ4   IOSTANDARD LVCMOS18  } [get_ports {LVDS1_D}]
set_property -dict {PACKAGE_PIN AH6   IOSTANDARD LVDS      } [get_ports {MGT_WR_IN1_P}]
set_property -dict {PACKAGE_PIN AJ6   IOSTANDARD LVDS      } [get_ports {MGT_WR_IN1_N}]
set_property -dict {PACKAGE_PIN AJ5   IOSTANDARD LVCMOS18  } [get_ports {SFP2_TX_DISABLE}]
set_property -dict {PACKAGE_PIN AK5   IOSTANDARD LVCMOS18  } [get_ports {SFP2_RX_LOS}]
set_property -dict {PACKAGE_PIN AK7   IOSTANDARD LVCMOS18  } [get_ports {SFP3_TX_DISABLE}]
set_property -dict {PACKAGE_PIN AK6   IOSTANDARD LVCMOS18  } [get_ports {SFP3_RX_LOS}]
set_property -dict {PACKAGE_PIN AF6   IOSTANDARD LVCMOS18  } [get_ports {SFP4_TX_DISABLE}]
set_property -dict {PACKAGE_PIN AF5   IOSTANDARD LVCMOS18  } [get_ports {SFP4_RX_LOS}]

# XU1 PL LED
set_property -dict {PACKAGE_PIN AE8   IOSTANDARD LVCMOS18  } [get_ports {LED2_N_PWR_SYNC}]

# I2C PL
set_property -dict {PACKAGE_PIN V3    IOSTANDARD LVCMOS18  } [get_ports {I2C_SCL}]
set_property -dict {PACKAGE_PIN Y7    IOSTANDARD LVCMOS18  } [get_ports {I2C_SDA}]