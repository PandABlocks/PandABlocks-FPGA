# Create a project named inenc_tb
create_project inenc_top_module_tb ../../build/tests/inenc_tb -force -part xc7z030sbg485-1

# Load and compile all the files required
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -norecurse {../../common/vhdl/defines/support.vhd 
../../common/vhdl/prescaler.vhd 
../../common/vhdl/defines/top_defines.vhd 
../../common/vhdl/delay_line.vhd 
../../common/vhdl/qdecoder.vhd 
../../common/vhdl/ssi_clock_gen.vhd 
../../common/vhdl/shifter_in.vhd 
../../common/vhdl/serial_link_detect.vhd 
../../common/vhdl/biss_crc.vhd 
../../common/vhdl/ssi_master.vhd 
../../common/vhdl/ssi_sniffer.vhd 
../../modules/qdec/vhdl/qdec.vhd 
../../common/vhdl/biss_sniffer.vhd 
../../common/vhdl/bitmux.vhd 
../../modules/base/vhdl/inenc.vhd 
../PandABox/autogen/inenc_ctrl.vhd 
../../modules/base/vhdl/inenc_block.vhd 
../../modules/base/vhdl/inenc_top.vhd 
../../common/vhdl/defines/slow_defines.vhd 
../../common/vhdl/defines/operator.vhd  
../PandABox/autogen/addr_defines.vhd 
../../common/vhdl/biss_slave.vhd
../../tests/sim/panda_inenc/bench/inenc_top_tb.vhd
}

# Update compile order 
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set result_from_test 0;
set test_passed 0;
set test_failed 0;
set loop_cnt 0;

set val0 0;
set val1 0;
set val2 0;
set val3 0;

set bits_val0 32;
set bits_val1 24;
set bits_val2 16;
set bits_val3 8;


# Count from 0 to 7
while {$loop_cnt < 8} {

    # I couldnt think of any other way of doing this as i did try and 
    # pass in the values using tcl variable but vivado did like it.
    if {$loop_cnt == 0} {
        # Change the number of BITS to 32, 24, 16 and 8
        set_property GENERIC {bits0=32 bits1=24 bits2=16 bits3=8} [get_filesets sim_1] 
    } elseif {$loop_cnt == 1} { 
        # Change the number of BITS to 31, 23, 15 and 7        
        set_property GENERIC {bits0=31 bits1=23 bits2=15 bits3=7} [get_filesets sim_1] 
    } elseif {$loop_cnt == 2} {
        # Change the number of BITS to 30, 22, 14 and 6
        set_property GENERIC {bits0=30 bits1=22 bits2=14 bits3=6} [get_filesets sim_1] 
    } elseif {$loop_cnt == 3} {
        # Change the number of BITS to 29, 21, 13 and 5
        set_property GENERIC {bits0=29 bits1=21 bits2=13 bits3=5} [get_filesets sim_1] 
    } elseif {$loop_cnt == 4} {
        # Change the number of BITS to 28, 20, 12 and 4
        set_property GENERIC {bits0=28 bits1=20 bits2=12 bits3=4} [get_filesets sim_1] 
    } elseif {$loop_cnt == 5} {
        # Change the number of BITS to 27, 19, 11 and 3
        set_property GENERIC {bits0=27 bits1=19 bits2=11 bits3=3} [get_filesets sim_1]
    } elseif {$loop_cnt == 6} {     
       # Change the number of BITS to 26, 18, 10 and 2
        set_property GENERIC {bits0=26 bits1=18 bits2=10 bits3=2} [get_filesets sim_1] 
    } elseif {$loop_cnt == 7} {
        # Change the number of BITS to 25, 17, 9 and 1
        set_property GENERIC {bits0=25 bits1=17 bits2=9 bits3=1} [get_filesets sim_1] 
    }

    launch_simulation

    #run 80us
    run -all

    # Get the value test_result from the source code
    set result_from_test [get_value test_result];

    # Check the BITS for component 0    
    set val0 [get_value bits0];
    # Check the BITS for component 1
    set val1 [get_value bits1];
    # Check the BITS for component 2
    set val2 [get_value bits2];
    # Check the BITS for component 3
    set val3 [get_value bits3];
    
    puts " $val0 ";
    puts " $val1 ";
    puts " $val2 ";
    puts " $val3 ";
    

    # Check the error signal  
    # If it has failed increment passed variable
    if {$result_from_test == 1} {
        incr test_passed +1;
        puts " Test has passed ";               
    # Else it has passed increment failed variable
    } else {
        incr test_failed +1;
        puts " Test has failed ";
    }
    
    close_sim
    
    incr loop_cnt +1; 
            
}

# Print the number of tests passed or failed
puts "Test passed $test_passed";
puts "Test failed $test_failed";

