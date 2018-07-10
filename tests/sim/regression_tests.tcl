
# outenc entity and tb component different also no component called quardin_posn
# panda_pcap 
#       1. apis_tb.v can't find where it is used
#       2. panda_pcap_dsp_tb.v can't find a component called pcap_dsp
#       3. panda_pcap_arming_tb.v   can't find a textio file arming_in.txt  
# panda_ssi_tb.v can't find the components ssimstr and ssislv

  
# Tests
# 1.  adder_tb          -- There is a one or two clock difference between vhd and python modules
#                       -- the testbench that runs here is a vhdl one. The veriolg one does match 
#                       -- the python reference module.     
# 2.  panda_srgate_tb   -- Works      
# 3.  panda_pulse_tb    -- Works 
# 4.  panda_pcomp_tb    -- Works
# 5.  pcap_core_tb      -- Works
# 6.  panda_lut_tb      -- Works
# 7.  panda_div_tb      -- Works
# 8.  panda_clock_tb    -- Works  
# 9.  panda_filter      -- Works
# 10. panda_sequnecer   -- Works  
# 11. panda_bits_tb     -- Works
# 12. panda_counter_tb  -- Works
# 13. panda_pgen_tb     -- Index to a text file in pgen_reg_in.txt (PGEN_1000.txt)


# Additional tests 
# 1. panda_biss         -- There are two tests in here 
#                       -- Test 1 verilog textio two biss sniffers
#                       -- Test 2 vhdl Master and Slave connected together random input data and BITS
# 2. panda_inenc        -- Inenc module level test contains a biss_sniffer it compiles, run and checks results tcl script    
# 3. panda_outenc       -- 
# 4. panda_slowctrl     -- ERROR: formal port inenc_protocol of mode out cannot be associated with actual port inenc_protocol of mode buffer [/home/zhz92437/code_panda/PandaFPGA/SlowFPGA/src/hdl/zynq_interface.vhd:119]
#                       -- ERROR: formal port outenc_protocol of mode out cannot be associated with actual port outenc_protocol of mode buffer [/home/zhz92437/code_panda/PandaFPGA/SlowFPGA/src/hdl/zynq_interface.vhd:120] 
# 5. panda_status       -- Don't know what this was testing                                      

# Create a vivado project called regression_tests
create_project regression_tests ../../build/tests/regression_tests -force -part xc7z030sbg485-1 


set result_from_test 0;
set test_passed_cnt 0;
set test_failed_cnt 0;

set test_passed are;
set test_failed are;


# Test array (add test here)
array set tests { 
        panda_bits_tb 12
        panda_counter_tb 11    
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
../../tests/sim/panda_counter/bench/panda_counter_tb.v
../../tests/sim/panda_bits/bench/panda_bits_tb.v
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


