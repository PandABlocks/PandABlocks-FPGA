set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
# ----------------------------------------------------------------------------------
# Important! Do not remove this constraint!
# This property ensures that all unused pins are set to high impedance.
# If the constraint is removed, all unused pins have to be set to HiZ in the top level file.
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

#set_property -dict {PACKAGE_PIN AG13  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[0]}]
#set_property -dict {PACKAGE_PIN AH13  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[0]}]
#set_property -dict {PACKAGE_PIN AF11  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[1]}]
#set_property -dict {PACKAGE_PIN AG11  IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[1]}]
# Temporarily swap to allow testing on ST1
set_property -dict {PACKAGE_PIN AJ10 IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[0]}]
set_property -dict {PACKAGE_PIN AK10 IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[0]}]
set_property -dict {PACKAGE_PIN AK9 IOSTANDARD LVDS} [get_ports {PANEL_F_DO_P[1]}]
set_property -dict {PACKAGE_PIN AK8 IOSTANDARD LVDS} [get_ports {PANEL_F_DO_N[1]}]
