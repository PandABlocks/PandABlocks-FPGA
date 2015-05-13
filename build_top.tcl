# Create an in-memory project
create_project -in_memory -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

set_property "default_lib" "xil_defaultlib" [current_project]
set_property "target_language" "VHDL" [current_project]

# Read design files
read_bd   panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd
read_vhdl ../src/hdl/axi4_lite_memif.vhd
read_vhdl ../src/hdl/panda_spbram.vhd
read_vhdl ../src/hdl/panda_top.vhd

# Read constraint files
read_xdc  ../src/const/panda_top.xdc
read_xdc  ../src/const/panda_user.xdc

synth_design -top panda_top

opt_design

place_design

route_design

write_checkpoint -force panda_top_routed.dcp
report_utilization -file panda_top_routed.rpt

write_debug_probes panda_top.ltx
write_bitstream -force panda_top.bit
