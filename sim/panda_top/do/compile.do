file delete -force read_from_hp1.txt

set SRC {../../../src/hdl}
set IP {../../../output/ip_repo}
set MODEL {../../panda_top/bench/zynq_model}
set SLOW {../../../../SlowFPGA/src/hdl}

#do ../bench/zynq_model/zynq_ps.sim/sim_1/behav/zynq_ps_wrapper_compile.do

# Compile Sources
#
vcom -64 -93 -work xil_defaultlib  \
"../bench/panda_ps_wrapper.vhd" \
"${IP}/pcap_dma_fifo/sim/pcap_dma_fifo.vhd"\
"${IP}/pgen_dma_fifo/sim/pgen_dma_fifo.vhd"\
"${IP}/pcomp_dma_fifo/sim/pcomp_dma_fifo.vhd"\
"${IP}/pulse_queue/sim/pulse_queue.vhd"\
"${SRC}/defines/type_defines.vhd" \
"${SRC}/defines/top_defines.vhd" \
"${SRC}/defines/panda_version.vhd" \
"${SRC}/bitmux.vhd" \
"${SRC}/posmux.vhd" \
"${SRC}/autogen/addr_defines.vhd" \
"${SRC}/autogen/panda_busses.vhd" \
"${SRC}/autogen/div_ctrl.vhd" \
"${SRC}/autogen/pulse_ctrl.vhd" \
"${SRC}/autogen/seq_ctrl.vhd" \
"${SRC}/autogen/inenc_ctrl.vhd" \
"${SRC}/autogen/outenc_ctrl.vhd" \
"${SRC}/autogen/counter_ctrl.vhd" \
"${SRC}/autogen/pcomp_ctrl.vhd" \
"${SRC}/autogen/pgen_ctrl.vhd" \
"${SRC}/autogen/bits_ctrl.vhd" \
"${SRC}/autogen/lut_ctrl.vhd" \
"${SRC}/autogen/srgate_ctrl.vhd" \
"${SRC}/autogen/clocks_ctrl.vhd" \
"${SRC}/autogen/adder_ctrl.vhd" \
"${SRC}/csr_if.vhd" \
"${SRC}/ttlout_block.vhd" \
"${SRC}/ttlout_top.vhd" \
"${SRC}/ttlin_top.vhd" \
"${SRC}/lvdsout_block.vhd" \
"${SRC}/lvdsout_top.vhd" \
"${SRC}/lvdsin_top.vhd" \
"${SRC}/lut.vhd" \
"${SRC}/lut_block.vhd" \
"${SRC}/lut_top.vhd" \
"${SRC}/srgate.vhd" \
"${SRC}/srgate_block.vhd" \
"${SRC}/srgate_top.vhd" \
"${SRC}/div.vhd" \
"${SRC}/div_block.vhd" \
"${SRC}/div_top.vhd" \
"${SRC}/pulse.vhd" \
"${SRC}/pulse_block.vhd" \
"${SRC}/pulse_top.vhd" \
"${SRC}/spbram.vhd" \
"${SRC}/sequencer_table.vhd" \
"${SRC}/sequencer.vhd" \
"${SRC}/sequencer_block.vhd" \
"${SRC}/sequencer_top.vhd" \
"${SRC}/ssislv.vhd" \
"${SRC}/ssimstr.vhd" \
"${SRC}/qenc.vhd" \
"${SRC}/qdec.vhd" \
"${SRC}/quadin.vhd" \
"${SRC}/quadout.vhd" \
"${SRC}/inenc.vhd" \
"${SRC}/inenc_block.vhd" \
"${SRC}/inenc_top.vhd" \
"${SRC}/outenc.vhd" \
"${SRC}/outenc_block.vhd" \
"${SRC}/outenc_top.vhd" \
"${SRC}/sequencer.vhd" \
"${SRC}/sequencer_top.vhd" \
"${SRC}/counter.vhd" \
"${SRC}/counter_block.vhd" \
"${SRC}/counter_top.vhd" \
"${SRC}/pcomp_table.vhd" \
"${SRC}/pcomp.vhd" \
"${SRC}/pcomp_block.vhd" \
"${SRC}/pcomp_top.vhd" \
"${SRC}/clocks.vhd" \
"${SRC}/clocks_block.vhd" \
"${SRC}/clocks_top.vhd" \
"${SRC}/adder.vhd" \
"${SRC}/adder_block.vhd" \
"${SRC}/adder_top.vhd" \
"${SRC}/bits.vhd" \
"${SRC}/bits_block.vhd" \
"${SRC}/bits_top.vhd" \
"${SRC}/reg.vhd" \
"${SRC}/reg_top.vhd" \
"${SRC}/axi_write_master.vhd" \
"${SRC}/pcap_core_ctrl.vhd" \
"${SRC}/pcap_posproc.vhd" \
"${SRC}/pcap_frame.vhd" \
"${SRC}/pcap_arming.vhd" \
"${SRC}/pcap_buffer.vhd" \
"${SRC}/pcap_core.vhd" \
"${SRC}/pcap_dma.vhd" \
"${SRC}/pcap_top.vhd" \
"${SRC}/slow_tx.vhd" \
"${SRC}/slow_rx.vhd" \
"${SRC}/slowctrl.vhd" \
"${SRC}/slowctrl_block.vhd" \
"${SRC}/slowctrl_top.vhd" \
"${SRC}/axi_read_master.vhd" \
"${SRC}/table_read_engine.vhd" \
"${SRC}/pgen.vhd" \
"${SRC}/pgen_block.vhd" \
"${SRC}/pgen_top.vhd" \
"${SRC}/top.vhd"          \

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
