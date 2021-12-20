
# TCL script to run a single test.
#      make single_hdl_test TEST="module number"
# where module is the name of the module in lower case eg lut and number is the
# test number eg 4 (make single_hdl_test TEST= "lut 4")

set TOP_DIR         [lindex $argv 0]
set TARGET_DIR      [lindex $argv 1]
set TGT_BUILD_DIR   [lindex $argv 2]
set BUILD_DIR       [lindex $argv 3]
set MODULES_IND     4

# Need to source the target specific tcl file to get the FPGA part string
source $TARGET_DIR/target_incl.tcl

create_project single_test single_test -force -part $FPGA_PART

if {$argc > $MODULES_IND} {
    set module [lindex $argv $MODULES_IND]
    set test   [lindex $argv $MODULES_IND]_[lindex $argv $MODULES_IND+1]_tb
} else {
    puts "No argument given, please set TEST input. lut_1_tb running as default"
    set module lut
    set test $module_1_tb
}
source $BUILD_DIR/hdl_timing/$module/$module.tcl

# Load all the common source files
add_files -norecurse \
    $TOP_DIR/common/hdl \
    $TOP_DIR/common/hdl/defines \
    $TOP_DIR/tests/hdl/top_defines.vhd


puts "###############################################################################################";
puts "                                           test $test"                                          ;
puts "###############################################################################################";

set_property top $test [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

launch_simulation

restart
run -all

# All the testbenchs have a signal called test_result
# this is used to indicate when the test fails i.e.
# test_result = 1 -- test has failed
# test_result = 0 -- test has passed
set result_from_test [get_value test_result];

puts "The test result is $test";

# Check to see if the test has passed or failed increment
# test_passed or test_failed variables and append result into variable
if {$result_from_test == 1} {
    incr test_failed_cnt +1;
    puts "###############################################################################################";
    puts "                                      $test has failed"                                         ;
    puts "###############################################################################################";
    append test_failed ", " \n "$test_failed_cnt." $test;

} else {
    incr test_passed_cnt +1;
    puts "###############################################################################################";
    puts "                                      $test has passed"                                         ;
    puts "###############################################################################################";
    append test_passed ", " \n "$test_passed_cnt." $test;
}

close_sim

