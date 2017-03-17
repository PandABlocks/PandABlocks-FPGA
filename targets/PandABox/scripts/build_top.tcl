#
# Generate top-level firmware
#

# Source directory
set TOP_DIR [lindex $argv 0]

# Source directory
set TARGET_DIR [lindex $argv 1]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 2]

# FMC and SFP Application Names are passed as arguments
set FMC_DESIGN [lindex $argv 3]
set SFP_DESIGN [lindex $argv 4]

# Create project
create_project -force panda_top $BUILD_DIR/panda_top -part xc7z030sbg485-1

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
set_msg_config -severity "CRITICAL WARNING" -new_severity ERROR

#
# STEP#1: setup design sources and constraints
#
# Import IPs
add_files -norecurse $BUILD_DIR/ip_repo/pulse_queue/pulse_queue.xci
add_files -norecurse $BUILD_DIR/ip_repo/pcap_dma_fifo/pcap_dma_fifo.xci
add_files -norecurse $BUILD_DIR/ip_repo/pgen_dma_fifo/pgen_dma_fifo.xci
add_files -norecurse $BUILD_DIR/ip_repo/pcomp_dma_fifo/pcomp_dma_fifo.xci
add_files -norecurse $BUILD_DIR/ip_repo/slow_cmd_fifo/slow_cmd_fifo.xci
add_files -norecurse $BUILD_DIR/ip_repo/fmcgtx/fmcgtx.xci
add_files -norecurse $BUILD_DIR/ip_repo/sfpgtx/sfpgtx.xci

# Read Zynq block design
read_bd   $BUILD_DIR/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

# Read design files
add_files -norecurse $TOP_DIR/common/vhdl
add_files -norecurse $TOP_DIR/modules/adder/vhdl
add_files -norecurse $TOP_DIR/modules/base/vhdl
add_files -norecurse $TOP_DIR/modules/bits/vhdl
add_files -norecurse $TOP_DIR/modules/clocks/vhdl
add_files -norecurse $TOP_DIR/modules/counter/vhdl
add_files -norecurse $TOP_DIR/modules/div/vhdl
add_files -norecurse $TOP_DIR/modules/lut/vhdl
add_files -norecurse $TOP_DIR/modules/pcap/vhdl
add_files -norecurse $TOP_DIR/modules/pcomp/vhdl
add_files -norecurse $TOP_DIR/modules/pgen/vhdl
add_files -norecurse $TOP_DIR/modules/posenc/vhdl
add_files -norecurse $TOP_DIR/modules/positions/vhdl
add_files -norecurse $TOP_DIR/modules/pulse/vhdl
add_files -norecurse $TOP_DIR/modules/qdec/vhdl
add_files -norecurse $TOP_DIR/modules/seq/vhdl
add_files -norecurse $TOP_DIR/modules/slow/vhdl
add_files -norecurse $TOP_DIR/modules/srgate/vhdl
add_files $TOP_DIR/modules/$FMC_DESIGN/vhdl
add_files $TOP_DIR/modules/$SFP_DESIGN/vhdl
add_files -norecurse $TOP_DIR/modules/$SFP_DESIGN/vhdl/sfpgt_loopback/gt_rom_init_rx.dat
add_files -norecurse $TOP_DIR/modules/$SFP_DESIGN/vhdl/sfpgt_loopback/gt_rom_init_tx.dat

# Read auto generated files
add_files -norecurse $BUILD_DIR/autogen

# Read constraint files
read_xdc $TOP_DIR/modules/$FMC_DESIGN/const/fmc.xdc
read_xdc $TOP_DIR/modules/$SFP_DESIGN/const/sfp.xdc
read_xdc $TARGET_DIR/const/panda-timing.xdc
read_xdc $TARGET_DIR/const/panda-post_synth.xdc
read_xdc $TARGET_DIR/const/panda-physical.xdc
set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-post_synth.xdc]
set_property used_in_synthesis false [get_files $TARGET_DIR/const/panda-physical.xdc]

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

# STEP#post5: report IO
report_io -verbose -file post_route_report_io.rpt

#
# STEP#5: generate a bitstream
#
write_bitstream -force panda_top.bit

#
# Export HW for SDK
#
#file mkdir $BUILD_DIR/panda_top/panda_top.sdk
write_hwdef -file $BUILD_DIR/panda_top_wrapper.hdf -force

close_project
