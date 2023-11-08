#
# Generate IP Cores
#

set TOP [lindex $argv 0]

set IP_PROJ [lindex $argv 1]

set BUILD_DIR [lindex $argv 2]

set IP [lindex $argv 3]

set IP_TCL [lindex $argv 4]

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

# Procedure for modifying generated sources
proc replaceInFile {file searchPat oldVal newVal} {
    set fd [open $file r]
    set newfd [open ${file}.tmp w]
    while {[gets $fd line] >= 0} {
        if {[string match $searchPat $line] == 1} {
            regsub $oldVal $line $newVal newline
            puts $newfd $newline
        } else {
            puts $newfd $line
        }
    }
    close $fd
    close $newfd
    file rename -force ${file}.tmp $file
}

# Check if patch function defined for IP and run
if {[llength [info proc patch]] > 0} {
    patch $BUILD_DIR
}

close_project

