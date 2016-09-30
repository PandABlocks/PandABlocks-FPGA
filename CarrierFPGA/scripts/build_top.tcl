# Source directory
set SRCDIR [lindex $argv 0]
set_param board.repoPaths $SRCDIR/configs

# Build directory
set BUILDIR [lindex $argv 1]

# FMC and SFP Application Names are passed as arguments
set FMC_DESIGN [lindex $argv 2]
set SFP_DESIGN [lindex $argv 3]

# Create project
create_project -force panda_top $BUILDIR/panda_top -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_top]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

#
# Warning supression
#
# Suppress Verilog file related warnings
set_msg_config -id {[Synth 8-2644]} -suppress

# Elevate critical warnings
# set_msg_config -severity "CRITICAL WARNING" -new_severity ERROR

#
# STEP#1: setup design sources and constraints
#
# Read design files
read_bd   $BUILDIR/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd
add_files $SRCDIR/src/hdl/autogen
add_files $SRCDIR/src/hdl/defines
add_files $SRCDIR/src/hdl/base
add_files $SRCDIR/src/hdl/FMC/$FMC_DESIGN/hdl
add_files $SRCDIR/src/hdl/SFP/$SFP_DESIGN/hdl

# Import IPs
add_files -norecurse $BUILDIR/ip_repo/pulse_queue/pulse_queue.xci
add_files -norecurse $BUILDIR/ip_repo/pcap_dma_fifo/pcap_dma_fifo.xci
add_files -norecurse $BUILDIR/ip_repo/pgen_dma_fifo/pgen_dma_fifo.xci
add_files -norecurse $BUILDIR/ip_repo/pcomp_dma_fifo/pcomp_dma_fifo.xci
add_files -norecurse $BUILDIR/ip_repo/slow_cmd_fifo/slow_cmd_fifo.xci
add_files -norecurse $BUILDIR/ip_repo/fmcgtx/fmcgtx.xci
add_files -norecurse $BUILDIR/ip_repo/sfpgtx/sfpgtx.xci
#add_files -norecurse $BUILDIR/ip_repo/ila_32x8K/ila_32x8K.xci

# Read constraint files
read_xdc $SRCDIR/src/hdl/FMC/$FMC_DESIGN/const/fmc.xdc
read_xdc $SRCDIR/src/hdl/SFP/$SFP_DESIGN/const/sfp.xdc
read_xdc $SRCDIR/src/const/panda_top.xdc

# Report IP Status before starting P&R
report_ip_status

#
# STEP#2: run synthesis, report utilization and timing estimates, write
# checkpoint design
#
synth_design -top panda_top -flatten_hierarchy rebuilt
write_checkpoint -force post_synth
report_timing_summary -file post_synth_timing_summary.rpt

#
# STEP#3: run placement and logic optimzation, report utilization and timing
# estimates, write checkpoint design
#
opt_design
place_design
phys_opt_design
write_checkpoint -force post_place
report_timing_summary -file post_place_timing_summary.rpt
write_debug_probes -force panda_top.ltx

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

#
# STEP#5: generate a bitstream
#
write_bitstream -force panda_top.bit

#
# Export HW for SDK
#
#file mkdir $BUILDIR/panda_top/panda_top.sdk
write_hwdef -file $BUILDIR/panda_top_wrapper.hdf -force

close_project
