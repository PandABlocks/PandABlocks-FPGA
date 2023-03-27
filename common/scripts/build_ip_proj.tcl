#
# Generate IP Project
#

set TGT_INCL_TCL [lindex $argv 0]

# Source directory
set PROJ_FILE [lindex $argv 1]

# Set external IP REPO path
set EXT_IP_REPO [lindex $argv 3]

source $TGT_INCL_TCL

# Create Managed IP Project
create_project -part $FPGA_PART -force -ip $PROJ_FILE

set_property target_language VHDL [current_project]
set_property target_simulator ModelSim [current_project]

set_property ip_repo_paths $EXT_IP_REPO [current_project]

close_project

