#
# Generate PS part of the firmware based as Zynq Block design
#

# Source directory
set TARGET_DIR [lindex $argv 0]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 1]/panda_ps

# Create project
create_project -force panda_ps $BUILD_DIR -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_ps]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create block design
# (THIS is exported from Vivado design tool)
source $TARGET_DIR/bd/panda_ps.tcl

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
generate_target all [get_files $BUILD_DIR/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd]
open_bd_design $BUILD_DIR/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

file mkdir $BUILD_DIR/panda_ps.sdk
write_hwdef -force -file $BUILD_DIR/panda_ps_wrapper.hdf

# Close block design and project
close_bd_design panda_ps
close_project
exit
