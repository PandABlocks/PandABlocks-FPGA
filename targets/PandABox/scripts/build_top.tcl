#
# Generate top-level firmware
#

#puts "NUMARGS = $argc" 
#set m 0
#foreach argValue $argv {
#   incr m
#   puts "ArgValue $m is $argValue"
#}
#puts "llength = [llength $argv]"
#puts $env(SFP_DESIGN)
#puts $env(SFP_SOCKETS)
#puts $env(FMC_DESIGN)
#if {$env(FMC_DESIGN) eq ""} { puts "FMC string empty" }

#puts "You have these environment variables set:"
#foreach index [array names env] {
#    puts "$index: $env($index)"
#}
#exit

# Source directory
set TOP_DIR [lindex $argv 0]

# Source directory
set TARGET_DIR [lindex $argv 1]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 2]

set IP_DIR [lindex $argv 3]

# FMC and SFP Application Names are passed as arguments

#set FMC_DESIGN [lindex $argv 3]
#set SFP_DESIGN [lindex $argv 4]


# Create project
#create_project -force panda_top $BUILD_DIR/panda_top -part xc7z030sbg485-1
create_project -force -in_memory panda_carrier_top $BUILD_DIR/panda_carier_top -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_carrier_top]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj
set_property part "xc7z030sbg485-1" [current_project]

#
# Warning suppression
#
# Suppress Verilog file related warnings
set_msg_config -id {[Synth 8-2644]} -suppress

# Elevate critical warnings
set_msg_config -severity "CRITICAL WARNING" -new_severity ERROR

#
# STEP#1: setup design sources and constraints
#
# Import IPs

#read_ip $IP_DIR/pulse_queue/pulse_queue.xci
#read_ip $IP_DIR/fifo_1K32/fifo_1K32.xci
#read_ip $IP_DIR/fifo_1K32_ft/fifo_1K32_ft.xci
#read_ip $IP_DIR/system_cmd_fifo/system_cmd_fifo.xci

source $BUILD_DIR/hdl/constraints.tcl

if {"acq430" in [string tolower $env(FMC_DESIGN)]} {
    read_ip $IP_DIR/fmc_acq430_ch_fifo/fmc_acq430_ch_fifo.xci
    read_ip $IP_DIR/fmc_acq430_sample_ram/fmc_acq430_sample_ram.xci
}
if {"acq427" in [string tolower $env(FMC_DESIGN)]} {
    read_ip $IP_DIR/fmc_acq430_ch_fifo/fmc_acq430_ch_fifo.xci
    read_ip $IP_DIR/fmc_acq427_dac_fifo/fmc_acq427_dac_fifo.xci
}
if {"loopback" in [string tolower $env(FMC_DESIGN)]} {
    read_ip $IP_DIR/fmcgtx/fmcgtx.xci
}
if {"loopback" in [string tolower $env(SFP_DESIGN)]} {
    read_ip $IP_DIR/sfpgtx/sfpgtx.xci
}
if {"udpontrig" in [string tolower $env(SFP_DESIGN)]} {
    read_ip $IP_DIR/ila_32x8K/ila_32x8K.xci
    read_ip -verbose $IP_DIR/eth_phy/eth_phy.xci
    # Disable DCP and XDC 
    set_property generate_synth_checkpoint false [get_files $IP_DIR/eth_phy/eth_phy.xci]
    generate_target all [get_ips eth_phy]
    set eth_phy_xdc [get_files -of_objects [get_files $IP_DIR/eth_phy/eth_phy.xci] -filter {FILE_TYPE == XDC}]
    set_property is_enabled false [get_files $eth_phy_xdc]
    report_compile_order -constraints
    read_ip -verbose $IP_DIR/eth_mac/eth_mac.xci
    # Disable DCP and XDC 
    set_property generate_synth_checkpoint false [get_files $IP_DIR/eth_mac/eth_mac.xci]
    generate_target all [get_ips eth_mac]
    set eth_mac_xdc [get_files -of_objects [get_files $IP_DIR/eth_mac/eth_mac.xci] -filter {FILE_TYPE == XDC}]
    set_property is_enabled false [get_files $eth_mac_xdc]
}

# Read Zynq block design
read_bd   $BUILD_DIR/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

# Read auto generated files
read_vhdl [glob $BUILD_DIR/hdl/*.vhd]

# Read design files

read_vhdl [glob $TOP_DIR/common/hdl/defines/*.vhd]
read_vhdl [glob $TARGET_DIR/hdl/*.vhd]
read_vhdl [glob $TOP_DIR/common/hdl/*.vhd]

if {$env(FMC_DESIGN) ne ""} {
	read_vhdl [glob $TOP_DIR/modules/fmc_[string tolower $env(FMC_DESIGN)]/vhdl/*.vhd]
	add_files $TOP_DIR/modules/fmc_[string tolower $env(FMC_DESIGN)]/vhdl/
}
if {$env(SFP_DESIGN) ne ""} {
    foreach SFP_TYPE $env(SFP_DESIGN) {
	    read_vhdl [glob $TOP_DIR/modules/sfp_[string tolower $SFP_TYPE]/vhdl/*.vhd]
    }
}


if {"udpontrig" in [string tolower $env(SFP_DESIGN)]} {
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/example_design_eth_phy/support/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/example_design_eth_phy/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/trimac_fifo_bloc/common/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/trimac_fifo_bloc/control/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/trimac_fifo_bloc/fifo/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/trimac_fifo_bloc/pat_gen/*.vhd]
    read_vhdl [glob $TOP_DIR/modules/sfp_udpontrig/vhdl/trimac_fifo_bloc/*.vhd]
}

if {"loopback" in [string tolower $env(SFP_DESIGN)]} {
    add_files -norecurse $TOP_DIR/modules/sfp_loopback/vhdl/gt_rom_init_rx.dat
    add_files -norecurse $TOP_DIR/modules/sfp_loopback/vhdl/gt_rom_init_tx.dat

}
#add_files $TOP_DIR/modules/$FMC_DESIGN/vhdl/

# Read constraint files
if {$env(FMC_DESIGN) ne ""} {
	read_xdc $TOP_DIR/modules/fmc_[string tolower $env(FMC_DESIGN)]/const/fmc.xdc
}
if {$env(SFP_DESIGN) ne ""} {
    read_xdc $TARGET_DIR/const/SFP1.xdc
    foreach SFP_TYPE $env(SFP_DESIGN) {
        read_xdc $TOP_DIR/modules/sfp_[string tolower $SFP_TYPE]/const/sfp.xdc
    }
    #foreach SFP_SOCKET $env(SFP_SOCKETS) {
	#    read_xdc $TARGET_DIR/const/[string toupper $SFP_SOCKET].xdc
    #}
}
#if {"SFP" in [string toupper $env(SFP_SOCKETS)]} {
#    read_xdc $TARGET_DIR/const/SFP1.xdc
#}
read_xdc $TARGET_DIR/const/panda-timing.xdc

if {"fmc_acq4??" in [string tolower $env(FMC_DESIGN)]} {
    read_xdc $TARGET_DIR/const/panda-physical430.xdc
    read_xdc $TARGET_DIR/const/panda-post_synth430.xdc
    set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-physical430.xdc]
    set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-post_synth430.xdc]
} else {
    read_xdc $TARGET_DIR/const/panda-physical.xdc
    read_xdc $TARGET_DIR/const/panda-post_synth.xdc
    set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-physical.xdc]
    set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-post_synth.xdc]
}   


#
# STEP#2: run synthesis, report utilization and timing estimates, write
# checkpoint design
#
synth_design -top panda_carrier_top -flatten_hierarchy rebuilt
write_checkpoint -force post_synth
report_timing_summary -file post_synth_timing_summary.rpt

#
# STEP#3: run placement and logic optimisation, report utilization and timing
# estimates, write checkpoint design
#
opt_design

place_design
phys_opt_design
write_checkpoint -force post_place
report_timing_summary -file post_place_timing_summary.rpt
write_debug_probes -force panda_carrier_top.ltx

#
# STEP#4: run router, report actual utilization and timing, write checkpoint
# design, run drc, write verilog and xdc out
#
route_design

write_checkpoint -force post_route
report_utilization -file post_route_utilization_summary.rpt

set timingreport [report_timing_summary -no_header -no_detailed_paths -return_string -file post_route_timing_summary.rpt]

if {! [string match -nocase {*timing constraints are met*} $timingreport]} {
    send_msg_id showstopper-0 error "Timing constraints weren't met."
    return -code error
}

# STEP#post5: report IO
report_io -verbose -file post_route_report_io.rpt

#
# STEP#5: generate a bitstream
#
write_bitstream -force panda_top.bit

#
# Export HW for SDK
#
write_hwdef -file $BUILD_DIR/panda_top_wrapper.hdf -force

close_project
exit
