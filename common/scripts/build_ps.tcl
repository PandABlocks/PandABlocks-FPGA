#
# Generate PS part of the firmware based as Zynq Block design
#

set TOP [lindex $argv 0]

# Source directory
set TARGET_DIR [lindex $argv 1]

# Build directory
set BUILD_DIR [lindex $argv 2]

# Output file
set OUTPUT_FILE [lindex $argv 3]

# Vivado run mode - gui or batch mode
set MODE [lindex $argv 4]

set_param board.repoPaths $TOP/common/configs

source $TARGET_DIR/target_incl.tcl

# Create project
create_project -part $FPGA_PART -force panda_ps $BUILD_DIR

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_ps]
if {[info exists BOARD_PART]} {set_property "board_part" $BOARD_PART $obj}
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create block design
# (THIS is exported from Vivado design tool)
source $TARGET_DIR/bd/panda_ps.tcl

# Exit script here if gui mode - i.e. if running 'make edit_ps_bd'
if {[string match "gui" [string tolower $MODE]]} { return }

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
set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files $OUTPUT_FILE] 
generate_target all [get_files $OUTPUT_FILE]

# Export to SDK
write_hw_platform -fixed -force $BUILD_DIR/panda_ps.xsa

