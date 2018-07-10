create_project biss_master_slave_tb ../../build/tests/biss_master_slave_tb -force -part xc7z030sbg485-1


# Compile all the vhdl and veriolg files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -norecurse {../../common/vhdl/defines/support.vhd
../../common/vhdl/prescaler.vhd
../../common/vhdl/shifter_in.vhd
../../common/vhdl/serial_link_detect.vhd
../../common/vhdl/biss_crc.vhd
../../common/vhdl/biss_clock_gen.vhd
../../common/vhdl/biss_master.vhd
../../common/vhdl/biss_slave.vhd
../../common/vhdl/biss_sniffer.vhd
../../tests/sim/panda_biss/bench/biss_master_slave_tb.vhd
../../tests/sim/panda_biss/bench/biss_result.v
../../tests/sim/panda_biss/bench/biss_sniffer_tb.v
}

# Load the textio files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {../../tests/sim/panda_biss/do/biss2.prn
../../tests/sim/panda_biss/do/biss0.prn
}

# Update the compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Set the tcl variables
set test_result 0;
set tests_run 0;
set test biss_sniffer_tb;
set test_passed " ";
set test_failed " ";

# Set the property on object
set_property top $test [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# launch vivado simulator
launch_simulation

# Run all textio file will stop 
# simulation when the end reached
run -all

# Capture the result of the test
set test_result [get_value test_result];

# Close vivado simulator
close_sim

# Indicate the status of the test
if {$test_result == 1} {
    append test_failed $test " has failed, ";
} else {
    append test_passed $test " has passed, ";
}

# Set the test to be run
set test biss_master_slave_tb;

# Set the properties on object 
set_property top $test [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# launch vivado simulator
launch_simulation


# Run for 5 milliseconds
run 5ms

# Capture the result of the test and how many tests that where run 
set test_result [get_value test_result];
set tests_run [get_value test_cnt];

# Close vivado simulator
close_sim

# Indicate the status of the test
if {$test_result == 1} {
    append test_failed $test " have failed whilst running $tests_run tests, ";
} else {
    append test_passed $test " have passed whilst running $tests_run tests, ";
}

# Check to see if the variable isn't empty
if {[string trim $test_failed] != " "} {
    puts "#################### $test_passed ####################";
}    
# Check to see if the variable isn't empty
if {[string trim $test_passed] != " "} {
    puts "#################### $test_failed ####################";
}     


