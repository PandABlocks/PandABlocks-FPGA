## Create an in-memory project
#create_project -in_memory -part xc7z030sbg485-1
#
## Set the directory path for the new project
#set proj_dir [get_property directory [current_project]]
#
## Set project properties
#set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" [current_project]
#set_property "default_lib" "xil_defaultlib" [current_project]
#set_property "simulator_language" "Mixed" [current_project]
#set_property "target_language" "VHDL" [current_project]

#
# This script generates PS part of the firmware based as Zynq
# Block design
#

# Set the reference directory to where the script is
#set origin_dir [file dirname [info script]]
set origin_dir .

# Set User Repository for PicoZed Board Definition File
set_param board.repoPaths ../configs

# Create project
create_project panda_top $origin_dir/panda_top -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_top]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

## Generate External IP into the project dir
#create_ip -name ila -vendor xilinx.com -library ip -version 5.1 -module_name ila_0
#set_property -dict [list CONFIG.C_PROBE0_WIDTH {64}] [get_ips ila_0]
#generate_target all [get_ips ila_0]
#synth_ip [get_ips ila_0]

# Read design files
read_bd   panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd
read_vhdl ../src/hdl/packages/top_defines.vhd
read_vhdl ../src/hdl/panda_csr_if.vhd
read_vhdl ../src/hdl/panda_spbram.vhd
read_vhdl ../src/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0_S00_AXI.vhd
read_vhdl ../src/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0.vhd
read_vhdl ../src/hdl/zebra_ssimstr.vhd
read_vhdl ../src/hdl/zebra_ssislv.vhd
read_vhdl ../src/hdl/panda_top.vhd

# Import IPs
import_ip ../src/ip_repo/ila_0/ila_0.xci

# Read constraint files
read_xdc  ../src/const/panda_user.xdc

#launch_runs synth_1
#wait_on_run synth_1
#launch_runs impl_1
#wait_on_run impl_1
#launch_runs impl_1 -to_step bitgen
#wait_on_run impl_1

# Report IP Status before starting P&R
report_ip_status

synth_design -top panda_top

opt_design
write_debug_probes -force panda_top.ltx

place_design

route_design

write_checkpoint -force panda_top_routed.dcp
report_utilization -file panda_top_routed.rpt

set timingreport [report_timing_summary -no_header -no_detailed_paths -return_string -file panda_top_timing.rpt]

if {! [string match -nocase {*timing constraints are met*} $timingreport]} {
    send_msg_id showstopper-0 error "Timing constraints weren't met."
    return -code error
}

write_bitstream -force panda_top.bit
