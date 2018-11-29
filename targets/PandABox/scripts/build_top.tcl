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

# Create project
#create_project -force panda_top $BUILD_DIR/panda_top -part xc7z030sbg485-1
create_project -force -in_memory panda_carrier_top $BUILD_DIR/FPGA/panda_carier_top -part xc7z030sbg485-1

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

read_xdc $TARGET_DIR/const/panda-timing.xdc
read_xdc $TARGET_DIR/const/panda-physical.xdc
read_xdc $TARGET_DIR/const/panda-post_synth.xdc
set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-physical.xdc]
set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-post_synth.xdc]

#
# STEP#1: setup design sources and constraints
#
# Import IPs

source $BUILD_DIR/hdl/constraints.tcl

# Read Zynq block design
read_bd   $BUILD_DIR/FPGA/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

# Read auto generated files
read_vhdl [glob $BUILD_DIR/hdl/*.vhd]

# Read design files

read_vhdl [glob $TOP_DIR/common/hdl/defines/*.vhd]
read_vhdl [glob $TOP_DIR/common/hdl/*.vhd]
read_vhdl [glob $TARGET_DIR/hdl/*.vhd]
read_vhdl [glob $TARGET_DIR/hdl/defines/*.vhd]

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
write_hwdef -file $BUILD_DIR/FPGA/panda_top_wrapper.hdf -force

close_project
exit
