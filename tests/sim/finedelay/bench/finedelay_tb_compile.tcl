set TOP [lindex $argv 0]
set BUILD_DIR [lindex $argv 1]
set MODE [lindex $argv 2]

create_project finedelay_tb $BUILD_DIR/build/tests/finedelay_tb -force -part xc7z030sbg485-1

set_property top finedelay_tb [current_fileset -simset]
add_files [glob $TOP/common/hdl/*.vhd]
add_files $TOP/tests/sim/finedelay/bench
set_property FILE_TYPE "VHDL 2008" [get_files $TOP/tests/sim/finedelay/bench/*.vhd]

launch_simulation
restart
run -all
