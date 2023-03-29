#
# Generate IP Cores
#

set IP_PROJ [lindex $argv 0]

set BUILD_DIR [lindex $argv 1]

set IP [lindex $argv 2]

set IP_TCL [lindex $argv 3]

# Open Managed IP Project
open_project $IP_PROJ

#Remove IP from project if already existing
if {[file exists $BUILD_DIR/$IP/$IP.xci]} {
    remove_files [get_files $BUILD_DIR/$IP/$IP.xci]
    file delete -force $BUILD_DIR/$IP
}

#Create and configure XCI file
source $IP_TCL

# Generate output products for global synthesis
set_property generate_synth_checkpoint false [get_files $BUILD_DIR/$IP/$IP.xci]
generate_target all [get_files $BUILD_DIR/$IP/$IP.xci]

# Check if patch function defined for IP and run
if {[llength [info proc patch]] > 0} {
    patch $BUILD_DIR
}

close_project

