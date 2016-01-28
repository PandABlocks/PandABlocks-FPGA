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

# Read design files
read_bd   panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd
read_vhdl ../src/hdl/defines/type_defines.vhd
read_vhdl ../src/hdl/defines/addr_defines.vhd
read_vhdl ../src/hdl/defines/top_defines.vhd
read_vhdl ../src/hdl/panda_csr_if.vhd
read_vhdl ../src/hdl/panda_spbram.vhd
read_vhdl ../src/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0_S00_AXI.vhd
read_vhdl ../src/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0.vhd
read_vhdl ../src/hdl/panda_ttlout_block.vhd
read_vhdl ../src/hdl/panda_ttlout_top.vhd
read_vhdl ../src/hdl/panda_ttlin_top.vhd
read_vhdl ../src/hdl/panda_lvdsout_block.vhd
read_vhdl ../src/hdl/panda_lvdsout_top.vhd
read_vhdl ../src/hdl/panda_lvdsin_top.vhd
read_vhdl ../src/hdl/panda_lut.vhd
read_vhdl ../src/hdl/panda_lut_block.vhd
read_vhdl ../src/hdl/panda_lut_top.vhd
read_vhdl ../src/hdl/panda_srgate.vhd
read_vhdl ../src/hdl/panda_srgate_block.vhd
read_vhdl ../src/hdl/panda_srgate_top.vhd
read_vhdl ../src/hdl/panda_div.vhd
read_vhdl ../src/hdl/panda_div_block.vhd
read_vhdl ../src/hdl/panda_div_top.vhd
read_vhdl ../src/hdl/panda_pulse.vhd
read_vhdl ../src/hdl/panda_pulse_block.vhd
read_vhdl ../src/hdl/panda_pulse_top.vhd
read_vhdl ../src/hdl/panda_counter.vhd
read_vhdl ../src/hdl/panda_counter_block.vhd
read_vhdl ../src/hdl/panda_counter_top.vhd
read_vhdl ../src/hdl/panda_sequencer.vhd
read_vhdl ../src/hdl/panda_sequencer_block.vhd
read_vhdl ../src/hdl/panda_sequencer_top.vhd
read_vhdl ../src/hdl/panda_ssislv.vhd
read_vhdl ../src/hdl/panda_ssimstr.vhd
read_vhdl ../src/hdl/panda_qenc.vhd
read_vhdl ../src/hdl/panda_qdec.vhd
read_vhdl ../src/hdl/panda_quadin.vhd
read_vhdl ../src/hdl/panda_quadout.vhd
read_vhdl ../src/hdl/panda_inenc.vhd
read_vhdl ../src/hdl/panda_inenc_block.vhd
read_vhdl ../src/hdl/panda_inenc_top.vhd
read_vhdl ../src/hdl/panda_outenc.vhd
read_vhdl ../src/hdl/panda_outenc_block.vhd
read_vhdl ../src/hdl/panda_outenc_top.vhd
read_vhdl ../src/hdl/panda_pcomp.vhd
read_vhdl ../src/hdl/panda_pcomp_block.vhd
read_vhdl ../src/hdl/panda_pcomp_top.vhd
read_vhdl ../src/hdl/panda_clocks.vhd
read_vhdl ../src/hdl/panda_clocks_block.vhd
read_vhdl ../src/hdl/panda_clocks_top.vhd
read_vhdl ../src/hdl/panda_bits.vhd
read_vhdl ../src/hdl/panda_bits_block.vhd
read_vhdl ../src/hdl/panda_bits_top.vhd
read_vhdl ../src/hdl/panda_reg.vhd
read_vhdl ../src/hdl//panda_axi3_write_master.vhd
read_vhdl ../src/hdl/panda_pcap_ctrl.vhd
read_vhdl ../src/hdl/panda_pcap_posproc.vhd
read_vhdl ../src/hdl/panda_pcap_dsp.vhd
read_vhdl ../src/hdl/panda_pcap.vhd
read_vhdl ../src/hdl/panda_pcap_top.vhd
read_vhdl ../src/hdl/panda_slowctrl_top.vhd
read_vhdl ../src/hdl/panda_top.vhd

# Import IPs
import_ip ./ip_repo/pulse_queue/pulse_queue.xci
import_ip ./ip_repo/pcap_dma_fifo/pcap_dma_fifo.xci

# Read constraint files
read_xdc  ../src/const/panda_top.xdc

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

# Export HW for SDK
file mkdir $origin_dir/panda_top/panda_top.sdk
write_hwdef -file $origin_dir/panda_top_wrapper.hdf -force
