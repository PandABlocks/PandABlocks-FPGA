#
# This script generates PS part of the firmware based as Zynq
# Block design
#

# Set the reference directory to where the script is
#set origin_dir [file dirname [info script]]
set origin_dir .

# Set User Repository for PicoZed Board Definition File
set_param project.boardPartRepoPaths ../configs

# Create project
create_project panda_ps $origin_dir/panda_ps -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_ps]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

set_property ip_repo_paths ../src/ip_repo [current_fileset]
update_ip_catalog

# Create block design
# (THIS is exported from Vivado design tool)
source ../src/bd/panda_ps.tcl

# Generate the wrapper
set design_name [get_bd_designs]
make_wrapper -files [get_files $design_name.bd] -top -import

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "panda_ps_wrapper" $obj

# Generate Output Files
generate_target all [get_files ./panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd]
open_bd_design $origin_dir/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

file mkdir $origin_dir/panda_ps/panda_ps.sdk
write_hwdef -file $origin_dir/panda_ps_wrapper.hdf
# write_hwdef -file $origin_dir/panda_ps/panda_ps.sdk/panda_ps_wrapper.hdf

# Close block design and project
close_bd_design panda_ps
close_project
exit
