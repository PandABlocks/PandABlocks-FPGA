# Disable DCP and XDC
set_property generate_synth_checkpoint false [get_files $IP_DIR/eth_phy/eth_phy.xci]
generate_target all [get_ips eth_phy]
set eth_phy_xdc [get_files -of_objects [get_files $IP_DIR/eth_phy/eth_phy.xci] -filter {FILE_TYPE == XDC}]
set_property is_enabled false [get_files $eth_phy_xdc]
report_compile_order -constraints

# Disable DCP and XDC
set_property generate_synth_checkpoint false [get_files $IP_DIR/eth_mac/eth_mac.xci]
generate_target all [get_ips eth_mac]
set eth_mac_xdc [get_files -of_objects [get_files $IP_DIR/eth_mac/eth_mac.xci] -filter {FILE_TYPE == XDC}]
set_property is_enabled false [get_files $eth_mac_xdc]

read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/example_design_eth_phy/support/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/example_design_eth_phy/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/trimac_fifo_bloc/common/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/trimac_fifo_bloc/control/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/trimac_fifo_bloc/fifo/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/trimac_fifo_bloc/pat_gen/*.vhd]
read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/hdl/trimac_fifo_bloc/*.vhd]