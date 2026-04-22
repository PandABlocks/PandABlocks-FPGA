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

