# Create an in-memory project
create_project -in_memory -part xc7z030sbg485-1

# Set the directory path for the new project
set project_dir [get_property directory [current_project]]

set src_dir "/home/iu42/hardware/trunk/FPGA/PandA-Motion-Project/PandaFPGA/src/hdl"

set_property "default_lib" "xil_defaultlib" [current_project]
set_property "target_language" "VHDL" [current_project]

# Read design files
read_vhdl "$src_dir/packages/top_defines.vhd"
read_vhdl "$src_dir/packages/support.vhd"
read_vhdl "$src_dir/packages/register_map.vhd"
read_vhdl "$src_dir/panda_digitalio.vhd"

synth_design -top panda_digitalio
