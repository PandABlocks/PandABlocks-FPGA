
# TCL script for running all tests
#   make hdl_test
# Alternatively run tests for a specific module
#   make hdl_test MODULES="module"
# Where module is the lowercase name of the module, lut for example. Multiple
# modules can be added by separating their names by a space(MODULES="bits lut")

# Tests
# 1.  bits_n_tb         --Works
# 2.  calc_n_tb         --Works
# 3.  clocks_n_tb       --Works
# 4.  counter_n_tb      --Works
# 5.  div_n_tb          --Works
# 6.  filter_n_tb       --Works
# 7.  lut_n_tb          --Works
# 8.  pcomp_n_tb        --Works Changed STATE output to be 3 bits rather than 2
# 9.  posenc_n_tb       --Works
# 10. pulse_n_tb        --Works
# 11. qdec_n_tb         --Works
# 12. srgate_n_tb       --Works


set TOP_DIR         [lindex $argv 0]
set TARGET_DIR      [lindex $argv 1]
set TGT_BUILD_DIR   [lindex $argv 2]
set BUILD_DIR       [lindex $argv 3]
set APP_BUILD_DIR   [lindex $argv 4]
set MODULES_IND     5

# Need to source the target specific tcl file to get the FPGA part string
source $TARGET_DIR/target_incl.tcl

# Create a vivado project called regression_tests
create_project regression_tests regression_tests \
 -force -part $FPGA_PART

set result_from_test 0;
set test_passed_cnt 0;
set test_failed_cnt 0;

set test_passed are;
set test_failed are;

foreach module [lrange $argv $MODULES_IND end] {
        source $BUILD_DIR/hdl_timing/$module/$module.tcl
}


# Load all the common source files
# Currently only the pulse queue ip is being used, as more modules are added it
# is expected that more common source files will be added

add_files -norecurse \
    $TOP_DIR/common/hdl/ \
    $TOP_DIR/common/hdl/defines \
    $APP_BUILD_DIR/autogen/hdl/top_defines_gen.vhd

set_property FILE_TYPE "VHDL 2008" [get_files $TOP_DIR/common/hdl/defines/top_defines.vhd]

# Loop through all the tests
foreach test [array names tests] {

    puts  "###############################################################################################";
    puts  "                                           $test"                                               ;
    puts  "###############################################################################################";

    set_property top $test [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

    launch_simulation

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
         puts "##################################### $test has failed #####################################";
         append test_failed ", " \n "$test_failed_cnt." $test;

    } else {
         incr test_passed_cnt +1;
         puts "##################################### $test has passed #####################################";
         append test_passed ", " \n "$test_passed_cnt." $test;
    }

    close_sim

}

# Print out the result of the regression run
if {$test_passed_cnt != 0} {
    puts "################################### Tests that have passed ###################################";
    puts "                                                                                              ";
    puts "Tests that have passed $test_passed                                                           ";
    puts "                                                                                              ";
    puts "Simulation has finished and the number of tests that have passed is $test_passed_cnt          ";
}
if {$test_failed_cnt != 0} {
    puts "################################### Tests that have failed ###################################";
    puts "                                                                                              ";
    puts "Tests that have failed $test_failed                                                           ";
    puts "                                                                                              ";
    puts "Simulation has finished and the number of tests that have failed is $test_failed_cnt          ";
    exit 1
}

