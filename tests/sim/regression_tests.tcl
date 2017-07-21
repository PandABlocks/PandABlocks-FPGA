
# biss_sniffer_tb.v NO biss0.prn
# outenc entity and tb component different also no component called quardin_posn
# panda_pcap 
#       1. apis_tb.v can't find where it is used
#       2. panda_pcap_dsp_tb.v can't find a component called pcap_dsp
#       3. panda_pcap_arming_tb.v   can't find a textio file arming_in.txt  
# panda_ssi_tb.v can't find the components ssimstr and ssislv

  

# Tests
# 1.  adder_tb          -- WORKS VHDL testbench self checks
# 2.  panda_srgate_tb   -- Need code changes      
# 3.  panda_pulse_tb    -- Problems negative edge a clock difference two edges doesn't work as I believe that the pulse is too short 
# 4.  panda_pcomp_tb    -- NOT WORKING NEEDS ALOT OF WORK (pcomp_reg_in.txt has PCOMP_1000.txt, PCOMP_2000.txt, PCOMP_3000.txt in it)
# 5.  pcap_core_tb      -- MULTIPLE TESTBENCHs NOT WORKING (pcap_core_tb.v is the only that uses textio files)
#		pcap_core_tb	-- ERR_STATUS problem it looks like its a python problem
# 6.  panda_lut_tb      -- WORKS
# 7.  panda_div_tb      -- WORKS
# 8.  panda_clock_tb    -- NOT WORKING (problem at the beginning of the test) counter reset so set to zero (32 bits register)
#                       -- used value is value -1 a two clock different need to be implemented CLOCKA_PERIOD, CLOCKB_PERIOD,
#                       -- CLOCKC_PERIOD, CLOCKD_PERIOD and reset_i  
# 9.  panda_filter      -- WORKS
# 10. panda_sequnecer   -- NOT WORKING (Results not the same as expected ones LOTS OF ERRORS) offset at the start causes the 
#                       -- expected results to offset by one clock from generated results  
# 11. bits              -- No testbench
# 12. counter           -- No testbench
# 13. pgen              -- No testbench
#../../tests/sim/panda_pcomp/bench/file_io.v should this be remove is it used in the pcap and seq tests

# Does the file_io.v work yes it does 


# Create a vivado project called regression_tests
create_project regression_tests ../../build/tests/regression_tests -force -part xc7z030sbg485-1 


set result_from_test 0;
set test_passed_cnt 0;
set test_failed_cnt 0;

set test_passed are;
set test_failed are;


# Test array (add test here)
array set tests { 
        panda_sequencer_2tb 10
        panda_filter_tb 9
        panda_clocks_tb 8
        panda_div_tb 7
        panda_lut_tb 6
        pcap_core_tb 5
        panda_pcomp_tb 4
        panda_pulse_tb 3
        panda_srgate_tb 2
        adder_tb 1
}


# Load the textio files into Vivado 
source "../../tests/sim/update_textio.tcl"


# Load all the source files
add_files -norecurse {../../modules/filter/vhdl/divider.vhd
../../modules/filter/vhdl/filter.vhd
../../modules/clocks/vhdl/clocks.vhd
../../modules/clocks/vhdl/clocks.vhd
../PandABox/ip_repo/pcomp_dma_fifo/pcomp_dma_fifo_funcsim.vhdl
../../modules/pcomp/vhdl/pcomp.vhd
../../common/vhdl/defines/support.vhd
../../modules/pulse/vhdl/pulse.vhd
../PandABox/ip_repo/pulse_queue/pulse_queue_funcsim.vhdl
../../modules/div/vhdl/div.vhd 
../../modules/lut/vhdl/lut.vhd
../../modules/pcomp/vhdl/pcomp_table.vhd
../../modules/srgate/vhdl/srgate.vhd
../../modules/adder/vhdl/adder.vhd
../../common/vhdl/defines/top_defines.vhd
../../common/vhdl/spbram.vhd
../../modules/seq/vhdl/sequencer_table.vhd
../../SlowFPGA/src/hdl/prescaler.vhd
../../modules/pcap/vhdl/pcap_arming.vhd
../../modules/pcap/vhdl/pcap_buffer.vhd
../../modules/pcap/vhdl/pcap_frame.vhd
../../common/vhdl/defines/operator.vhd
../../modules/pcap/vhdl/pcap_capture.vhd
../../modules/pcap/vhdl/pcap_core.vhd
../../modules/seq/vhdl/sequencer.vhd
../../modules/bits/vhdl/bits.vhd
../../modules/counter/vhdl/counter.vhd
../../modules/pgen/vhdl/pgen.vhd
../../tests/sim/panda_pcomp/bench/file_io.v
}


# Load all simulation source files 
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {../../tests/sim/panda_pulse/bench/panda_pulse_tb.v
../../tests/sim/panda_pcomp/bench/panda_pcomp_tb.v
../../tests/sim/panda_clocks/bench/panda_clocks_tb.v
../../tests/sim/panda_div/bench/panda_div_tb.v
../../tests/sim/panda_filter/bench/panda_filter_tb.v
../../tests/sim/panda_lut/bench/panda_lut_tb.v
../../tests/sim/panda_srgate/bench/panda_srgate_tb.v
../../tests/sim/panda_adder/bench/adder_tb.vhd
../../tests/sim/panda_pulse/bench/panda_pulse_tb.v
../../tests/sim/panda_pcap/bench/pcap_core_wrapper.vhd
../../tests/sim/panda_pcap/bench/pcap_core_tb.v
../../tests/sim/panda_pcap/bench/pcap_core_2tb.v
../../tests/sim/panda_sequencer/bench/panda_sequencer_tb.v
../../tests/sim/panda_sequencer/bench/panda_sequencer_2tb.v
}


# Loop through all the tests
foreach test [array names tests] { 

    puts  "###############################################################################################"
    puts  "                                           $test"
    puts  "###############################################################################################"           
    
    set_property top $test [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]

    launch_simulation

    run -all
  
    # All the testbenchs have a signal called test_result 
    # this is used to indicate when the test fails i.e.
    # test_result = 1 -- test has failed
    # test_result = 0 -- test has passed  
    get_value test_result; 
    get_object test_result;
    set result_from_test [get_value test_result];
  
    puts "The test result is $test" 
  
    # Check to see if the test has passed or failed increment 
    # test_passed or test_failed variables and append result into variable   
    if {$result_from_test == 1} {
         incr test_failed_cnt +1;
         puts "##################################### $test has failed #####################################"
         append test_failed ", " \n "$test_failed_cnt." $test  
         
    } else {
         incr test_passed_cnt +1;
         puts "##################################### $test has passed #####################################"
         append test_passed ", " \n "$test_passed_cnt." $test 
    }     
      
    close_sim

}

# Print out the result of the regression run
puts "################################### Tests that have passed ###################################"
puts "                                                                                              "
puts "Tests that have passed $test_passed";
puts "                                                                                              "    
puts "################################### Tests that have failed ###################################"
puts "                                                                                              "  
puts "Tests that have failed $test_failed";
puts "                                                                                              "
puts "################################# Test passed failed count ###################################"
puts "Simulation has finished and the number of tests that have passed is $test_passed_cnt";
puts "                                                                                              " 
puts "Simulation has finished and the number of tests that have failed is $test_failed_cnt";
puts "                                                                                              "


