#
# Generate Xilinx IP Cores
#

set TOP [lindex $argv 0]

# Source directory
set TARGET_DIR [lindex $argv 1]

# Build directory
set BUILD_DIR [lindex $argv 2]

# Vivado run mode - gui or batch mode
# Now unused
set MODE [lindex $argv 3]

set_param board.repoPaths $TOP/common/configs

source $TARGET_DIR/target_incl.tcl

# Create Managed IP Project
create_project -part $FPGA_PART -force -ip managed_ip_project $BUILD_DIR/managed_ip_project

# Set project properties
if {[info exists BOARD_PART]} {
    set_property "board_part" $BOARD_PART [current_project]
}

set_property target_language VHDL [current_project]
set_property target_simulator ModelSim [current_project]

foreach IP $TGT_IP {
    source $TOP/ip_defs/$IP.tcl
}

