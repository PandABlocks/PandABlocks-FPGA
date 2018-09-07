
# TCL script to run a single test.
#   make single_hdl_test TEST="module number"
# where module is the name of the module in lower case eg lut and number is the
# test number eg 4

create_project single_test ../../build/tests/single_test -force -part xc7z030sbg485-1

if {$argc > 0} {
	set module [lindex $argv 0]
	set test   [lindex $argv 0]_[lindex $argv 1]_tb
		source "../hdl_timing/$module/$module.tcl"

} else {
	source "../hdl_timing/lut/lut.tcl"
	set test lut_1_tb
}


# Load all the common source files
add_files -norecurse {
../../common/hdl/prescaler_pos.vhd
../../common/hdl/defines/support.vhd
../../common/ip_repo/pulse_queue/pulse_queue_funcsim.vhdl
../../common/hdl/qdecoder.vhd
../../common/hdl/qencoder.vhd
../../common/hdl/qenc.vhd
../../modules/filter/hdl/divider.vhd
}



puts  "###############################################################################################";
puts  "                                           $test"                                               ;
puts  "###############################################################################################";

set_property top $test [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

launch_simulation

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

