file delete -force read_from_hp1.txt

set SRC {../../../src/hdl}
set IP {../../../output/ip_repo}
set MODEL {../../panda_top/bench/zynq_model}

set SLOW {../../../../SlowFPGA/src/hdl}

vlib work
vlib msim

do bfm.do

# Compile Sources
#
vcom -64 -93 -work xil_defaultlib  \
"${IP}/pcap_dma_fifo/sim/pcap_dma_fifo.vhd"\
"${IP}/pulse_queue/sim/pulse_queue.vhd"\
"${SRC}/defines/type_defines.vhd" \
"${SRC}/defines/addr_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/defines/panda_version.vhd" \
"${SRC}/pulse2pulse.vhd" \
"${SRC}/panda_busses.vhd" \
"${SRC}/panda_csr_if.vhd" \
"${SRC}/panda_ttlout_block.vhd" \
"${SRC}/panda_ttlout_top.vhd" \
"${SRC}/panda_ttlin_top.vhd" \
"${SRC}/panda_lvdsout_block.vhd" \
"${SRC}/panda_lvdsout_top.vhd" \
"${SRC}/panda_lvdsin_top.vhd" \
"${SRC}/panda_lut.vhd" \
"${SRC}/panda_lut_block.vhd" \
"${SRC}/panda_lut_top.vhd" \
"${SRC}/panda_srgate.vhd" \
"${SRC}/panda_srgate_block.vhd" \
"${SRC}/panda_srgate_top.vhd" \
"${SRC}/panda_div.vhd" \
"${SRC}/panda_div_block.vhd" \
"${SRC}/panda_div_top.vhd" \
"${SRC}/panda_pulse.vhd" \
"${SRC}/panda_pulse_block.vhd" \
"${SRC}/panda_pulse_top.vhd" \
"${SRC}/panda_spbram.vhd" \
"${SRC}/panda_sequencer_table.vhd" \
"${SRC}/panda_sequencer.vhd" \
"${SRC}/panda_sequencer_block.vhd" \
"${SRC}/panda_sequencer_top.vhd" \
"${SRC}/panda_ssislv.vhd" \
"${SRC}/panda_ssimstr.vhd" \
"${SRC}/panda_qenc.vhd" \
"${SRC}/panda_qdec.vhd" \
"${SRC}/panda_quadin.vhd" \
"${SRC}/panda_quadout.vhd" \
"${SRC}/panda_inenc.vhd" \
"${SRC}/panda_inenc_block.vhd" \
"${SRC}/panda_inenc_top.vhd" \
"${SRC}/panda_outenc.vhd" \
"${SRC}/panda_outenc_block.vhd" \
"${SRC}/panda_outenc_top.vhd" \
"${SRC}/panda_sequencer.vhd" \
"${SRC}/panda_sequencer_top.vhd" \
"${SRC}/panda_counter.vhd" \
"${SRC}/panda_counter_block.vhd" \
"${SRC}/panda_counter_top.vhd" \
"${SRC}/panda_pcomp.vhd" \
"${SRC}/panda_pcomp_block.vhd" \
"${SRC}/panda_pcomp_top.vhd" \
"${SRC}/panda_clocks.vhd" \
"${SRC}/panda_clocks_block.vhd" \
"${SRC}/panda_clocks_top.vhd" \
"${SRC}/panda_bits.vhd" \
"${SRC}/panda_bits_block.vhd" \
"${SRC}/panda_bits_top.vhd" \
"${SRC}/panda_reg.vhd" \
"${SRC}/panda_reg_top.vhd" \
"${SRC}/panda_axi_write_master.vhd" \
"${SRC}/panda_pcap_ctrl.vhd" \
"${SRC}/panda_pcap_posproc.vhd" \
"${SRC}/panda_pcap_frame.vhd" \
"${SRC}/panda_pcap_arming.vhd" \
"${SRC}/panda_pcap_buffer.vhd" \
"${SRC}/panda_pcap_core.vhd" \
"${SRC}/panda_pcap_dma.vhd" \
"${SRC}/panda_pcap_top.vhd" \
"${SRC}/panda_slow_tx.vhd" \
"${SRC}/panda_slow_rx.vhd" \
"${SRC}/panda_slowctrl.vhd" \
"${SRC}/panda_slowctrl_block.vhd" \
"${SRC}/panda_slowctrl_top.vhd" \
"${SRC}/panda_top.vhd"          \

#
# Slow Controller
#
vcom -64 -93 -work xil_defaultlib  \
"${SLOW}/slow_defines.vhd"      \
"${SLOW}/slow_serial_if.vhd"    \
"${SLOW}/slow_top.vhd"          \



# Compile Testbench
#
vlog -work xil_defaultlib "../bench/incr_encoder_model.v" \

vcom -64 -93 -work xil_defaultlib  \
"../bench/test_interface.vhd" \
"../bench/SN65HVD05D.vhd" \
"../bench/SN75LBC174A.vhd" \
"../bench/SN75LBC175A.vhd" \
"../bench/daughter_card_model.vhd" \
"../bench/panda_top_tb.vhd"

vlog -work xil_defaultlib "../bench/test.v"

vopt -64 +acc -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -L generic_baseblocks_v2_1 -L fifo_generator_v12_0 -L axi_data_fifo_v2_1 -L axi_infrastructure_v1_1 -L axi_register_slice_v2_1 -L axi_protocol_converter_v2_1 -L axi_clock_converter_v2_1 -L blk_mem_gen_v8_2 -L axi_dwidth_converter_v2_1 -work xil_defaultlib xil_defaultlib.test xil_defaultlib.glbl -o test_opt


vsim -t 1ps -pli "/dls_sw/FPGA/Xilinx/Vivado/2015.1/lib/lnx64.o/libxil_vsim.so" -lib xil_defaultlib test_opt

do wave.do

run -all
