
# TCL script for running all tests
#   make hdl_test
# Alternatively run tests for a specific module
#   make hdl_test MODULE="module"
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



# Create a vivado project called regression_tests
create_project regression_tests ../../build/tests/regression_tests \
 -force -part xc7z030sbg485-1


set result_from_test 0;
set test_passed_cnt 0;
set test_failed_cnt 0;

set test_passed are;
set test_failed are;

if {$argc > 0} {
    foreach module $argv {
            source "../hdl_timing/$module/$module.tcl"
    }
} else {
    # Find all the tcl scripts in the hdl_timing directory and source them
    set mydir ../hdl_timing
    set subs [ glob -nocomplain -directory $mydir -type d *]
    # Load the modules files into Vivado
    foreach folder $subs {
        set path [split $folder /]
        source $folder/[lindex $path 2].tcl
    }
}
# Load all the common source files
# Currently only the pulse queue ip is being used, as more modules are added it
# is expected that more common source files will be added
add_files -norecurse {
    ../../common/hdl
    ../../common/hdl/defines
    ../../targets/PandABox/hdl/defines
    ../../tests/hdl/top_defines.vhd
}


# Loop through all the tests
foreach test [array names tests] {

    puts  "###############################################################################################";
    puts  "                                           $test"                                               ;
    puts  "###############################################################################################";

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

