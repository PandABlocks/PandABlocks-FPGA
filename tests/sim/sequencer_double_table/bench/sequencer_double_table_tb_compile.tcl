set TOP [lindex $argv 0]
set BUILD_DIR [lindex $argv 1]
set MODE [lindex $argv 2]
set TARGET sequencer_double_table
set TEST ${TARGET}_tb

create_project $TEST $BUILD_DIR/build/tests/$TEST -force -part xc7z030sbg485-1

set_property top $TEST [current_fileset -simset]
add_files $TOP/common/hdl/
add_files [glob $TOP/modules/seq/hdl/*.vhd]
add_files $TOP/tests/sim/$TARGET/bench
set_property FILE_TYPE "VHDL 2008" [get_files *.vhd]

launch_simulation
run -all
