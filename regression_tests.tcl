
# outenc entity and tb component different also no component called quardin_posn
# panda_pcap 
#       1. apis_tb.v can't find where it is used
#       2. panda_pcap_dsp_tb.v can't find a component called pcap_dsp
#       3. panda_pcap_arming_tb.v   can't find a textio file arming_in.txt  
# panda_ssi_tb.v can't find the components ssimstr and ssislv

  
# Tests
# 1.  calc_tb           -- There is a one or two clock difference between vhd and python modules
#                       -- the testbench that runs here is a vhdl one. The veriolg one does match
#                       -- the python reference module as there are three clocks before output changes.
# 2.  panda_srgate_tb       -- Works
# 3.  panda_pulse_tb        -- Works
# 4.  panda_pcomp_tb        -- Works
# 5.  pcap_core_tb          -- Works
# 6.  panda_lut_tb          -- Works
# 7.  panda_div_tb          -- Works
# 8.  panda_clock_tb        -- Works
# 9.  panda_filter          -- Works
# 10. panda_sequnecer       -- Works
# 11. panda_bits_tb         -- Works
# 12. panda_counter_tb      -- Works
#     panda_pgen_tb         -- Index to a text file in pgen_reg_in.txt (PGEN_1000.txt)
# 13  biss_sniffer_tb       -- Works textio files but no python model
# 15  biss_master_slave_tb  -- Works BiSS master connected to BiSS slave vhd



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
        bits_1_tb 12
        counter_1_tb 11
        counter_2_tb 11
        counter_3_tb 11
        counter_4_tb 11
        counter_5_tb 11
        counter_6_tb 11
        counter_7_tb 11
        filter_1_tb 9
        filter_2_tb 9
        filter_3_tb 9
        filter_4_tb 9
        filter_5_tb 9
        filter_6_tb 9
        filter_7_tb 9
        clocks_1_tb 8
        clocks_2_tb 8
        div_1_tb 7
        div_2_tb 7
        div_3_tb 7
        lut_1_tb 6
        lut_2_tb 6
        lut_3_tb 6
        lut_4_tb 6
        lut_5_tb 6
        lut_6_tb 6
        lut_7_tb 6
        pcomp_1_tb 4
        pcomp_2_tb 4
        pcomp_3_tb 4
        pcomp_4_tb 4
        pcomp_5_tb 4
        pcomp_6_tb 4
        pcomp_7_tb 4
        pcomp_8_tb 4
        pcomp_9_tb 4
        pcomp_10_tb 4
        pcomp_11_tb 4
        pcomp_12_tb 4
        pcomp_13_tb 4
        pcomp_14_tb 4
        pcomp_15_tb 4
        pcomp_16_tb 4
        pcomp_17_tb 4
        pcomp_18_tb 4
        pcomp_19_tb 4
        pcomp_20_tb 4
        pcomp_21_tb 4
        pulse_1_tb 3
        pulse_2_tb 3
        pulse_3_tb 3
        pulse_4_tb 3
        pulse_5_tb 3
        pulse_6_tb 3
        pulse_7_tb 3
        pulse_8_tb 3
        srgate_1_tb 2
        srgate_2_tb 2
        srgate_3_tb 2
        srgate_4_tb 2
        srgate_5_tb 2
        srgate_6_tb 2
        srgate_7_tb 2
        srgate_8_tb 2
        srgate_9_tb 2
        srgate_10_tb 2
        srgate_11_tb 2
        srgate_12_tb 2
        srgate_13_tb 2
        calc_1_tb 1
        calc_2_tb 1
        qdec_1_tb 5
        qdec_2_tb 5
        qdec_3_tb 5
        qdec_4_tb 5
        qdec_5_tb 5
}


# Load the textio files into Vivado 
source "../../update_textio.tcl"


# Load all the source files
add_files -norecurse {../../modules/filter/hdl/divider.vhd
../../common/hdl/prescaler_pos.vhd
../../modules/filter/hdl/filter.vhd
../../modules/clocks/hdl/clocks.vhd
../../modules/pcomp/hdl/pcomp.vhd
../../common/hdl/defines/support.vhd
../../modules/pulse/hdl/pulse.vhd
../../common/ip_repo/pulse_queue/pulse_queue_funcsim.vhdl
../../common/ip_repo/fifo_1K32/fifo_1K32_funcsim.vhdl
../../modules/div/hdl/div.vhd
../../modules/lut/hdl/lut.vhd
../../modules/srgate/hdl/srgate.vhd
../../modules/calc/hdl/calc.vhd
../../common/hdl/defines/top_defines.vhd
../../common/hdl/defines/operator.vhd
../../modules/bits/hdl/bits.vhd
../../modules/counter/hdl/counter.vhd
../../modules/qdec/hdl/qdec.vhd
../../common/hdl/qdecoder.vhd
}


# Load all simulation source files 
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {../hdl_timing/bits/timing001/hdl_timing.v
../hdl_timing/calc/timing001/hdl_timing.v
../hdl_timing/calc/timing002/hdl_timing.v
../hdl_timing/clocks/timing001/hdl_timing.v
../hdl_timing/clocks/timing002/hdl_timing.v
../hdl_timing/counter/timing001/hdl_timing.v
../hdl_timing/counter/timing002/hdl_timing.v
../hdl_timing/counter/timing003/hdl_timing.v
../hdl_timing/counter/timing004/hdl_timing.v
../hdl_timing/counter/timing005/hdl_timing.v
../hdl_timing/counter/timing006/hdl_timing.v
../hdl_timing/counter/timing007/hdl_timing.v
../hdl_timing/div/timing001/hdl_timing.v
../hdl_timing/div/timing002/hdl_timing.v
../hdl_timing/div/timing003/hdl_timing.v
../hdl_timing/filter/timing001/hdl_timing.v
../hdl_timing/filter/timing002/hdl_timing.v
../hdl_timing/filter/timing003/hdl_timing.v
../hdl_timing/filter/timing004/hdl_timing.v
../hdl_timing/filter/timing005/hdl_timing.v
../hdl_timing/filter/timing006/hdl_timing.v
../hdl_timing/filter/timing007/hdl_timing.v
../hdl_timing/filter/timing008/hdl_timing.v
../hdl_timing/filter/timing009/hdl_timing.v
../hdl_timing/lut/timing001/hdl_timing.v
../hdl_timing/lut/timing002/hdl_timing.v
../hdl_timing/lut/timing003/hdl_timing.v
../hdl_timing/lut/timing004/hdl_timing.v
../hdl_timing/lut/timing005/hdl_timing.v
../hdl_timing/lut/timing006/hdl_timing.v
../hdl_timing/lut/timing007/hdl_timing.v
../hdl_timing/pcomp/timing001/hdl_timing.v
../hdl_timing/pcomp/timing002/hdl_timing.v
../hdl_timing/pcomp/timing003/hdl_timing.v
../hdl_timing/pcomp/timing004/hdl_timing.v
../hdl_timing/pcomp/timing005/hdl_timing.v
../hdl_timing/pcomp/timing006/hdl_timing.v
../hdl_timing/pcomp/timing007/hdl_timing.v
../hdl_timing/pcomp/timing008/hdl_timing.v
../hdl_timing/pcomp/timing009/hdl_timing.v
../hdl_timing/pcomp/timing010/hdl_timing.v
../hdl_timing/pcomp/timing011/hdl_timing.v
../hdl_timing/pcomp/timing012/hdl_timing.v
../hdl_timing/pcomp/timing013/hdl_timing.v
../hdl_timing/pcomp/timing014/hdl_timing.v
../hdl_timing/pcomp/timing015/hdl_timing.v
../hdl_timing/pcomp/timing016/hdl_timing.v
../hdl_timing/pcomp/timing017/hdl_timing.v
../hdl_timing/pcomp/timing018/hdl_timing.v
../hdl_timing/pcomp/timing019/hdl_timing.v
../hdl_timing/pcomp/timing020/hdl_timing.v
../hdl_timing/pcomp/timing021/hdl_timing.v
../hdl_timing/posenc/timing001/hdl_timing.v
../hdl_timing/pulse/timing001/hdl_timing.v
../hdl_timing/pulse/timing002/hdl_timing.v
../hdl_timing/pulse/timing003/hdl_timing.v
../hdl_timing/pulse/timing004/hdl_timing.v
../hdl_timing/pulse/timing005/hdl_timing.v
../hdl_timing/pulse/timing006/hdl_timing.v
../hdl_timing/pulse/timing007/hdl_timing.v
../hdl_timing/pulse/timing008/hdl_timing.v
../hdl_timing/qdec/timing001/hdl_timing.v
../hdl_timing/qdec/timing002/hdl_timing.v
../hdl_timing/qdec/timing003/hdl_timing.v
../hdl_timing/qdec/timing004/hdl_timing.v
../hdl_timing/qdec/timing005/hdl_timing.v
../hdl_timing/srgate/timing001/hdl_timing.v
../hdl_timing/srgate/timing002/hdl_timing.v
../hdl_timing/srgate/timing003/hdl_timing.v
../hdl_timing/srgate/timing004/hdl_timing.v
../hdl_timing/srgate/timing005/hdl_timing.v
../hdl_timing/srgate/timing006/hdl_timing.v
../hdl_timing/srgate/timing007/hdl_timing.v
../hdl_timing/srgate/timing008/hdl_timing.v
../hdl_timing/srgate/timing009/hdl_timing.v
../hdl_timing/srgate/timing010/hdl_timing.v
../hdl_timing/srgate/timing011/hdl_timing.v
../hdl_timing/srgate/timing012/hdl_timing.v
../hdl_timing/srgate/timing013/hdl_timing.v
}


# Loop through all the tests
foreach test [array names tests] { 

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

}

# Print out the result of the regression run
if {$test_failed_cnt != 0} {
    puts "################################### Tests that have failed ###################################";
    puts "                                                                                              ";
    puts "Tests that have failed $test_failed                                                           ";
    puts "                                                                                              ";
    puts "Simulation has finished and the number of tests that have failed is $test_failed_cnt          ";
}
if {$test_passed_cnt != 0} {
    puts "################################### Tests that have passed ###################################";
    puts "                                                                                              ";
    puts "Tests that have passed $test_passed                                                           ";
    puts "                                                                                              ";
    puts "Simulation has finished and the number of tests that have passed is $test_passed_cnt          ";
}





