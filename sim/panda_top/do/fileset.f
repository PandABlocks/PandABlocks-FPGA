set PATH {../../../src}

vcom -work work "${PATH}/hdl/defines/type_defines.vhd"
vcom -work work "${PATH}/hdl/defines/top_defines.vhd"
vcom -work work "${PATH}/hdl/defines/addr_defines.vhd"
vcom -work work "${PATH}/hdl/panda_ssislv.vhd"
vcom -work work "${PATH}/hdl/panda_ssimstr.vhd"

vcom -work work "${PATH}/hdl/panda_qdec.vhd"
vcom -work work "${PATH}/hdl/panda_quadin.vhd"
vcom -work work "${PATH}/hdl/panda_qenc.vhd"
vcom -work work "${PATH}/hdl/panda_quadout.vhd"

vcom -work work "${PATH}/hdl/panda_digout.vhd"
vcom -work work "${PATH}/hdl/panda_digio.vhd"

vcom -work work "${PATH}/hdl/panda_encin.vhd"
vcom -work work "${PATH}/hdl/panda_encin_top.vhd"
vcom -work work "${PATH}/hdl/panda_encout.vhd"
vcom -work work "${PATH}/hdl/panda_encout_top.vhd"
vcom -work work "${PATH}/hdl/panda_csr_if.vhd"
vcom -work work "${PATH}/hdl/panda_pcomp.vhd"
vcom -work work "${PATH}/hdl/panda_pcomp_top.vhd"

vcom -work work "${PATH}/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0_S00_AXI.vhd"
vcom -work work "${PATH}/ip_repo/panda_pcap_1.0/hdl/panda_pcap_v1_0.vhd"

vcom -work work "../bench/test_interface.vhd"
vcom -work work "../bench/std_logic_textio.vhd"
vcom -work work "../bench/txt_util.vhd"
vcom -work work "../bench/panda_ps_emu.vhd"
vcom -work work "../bench/daughter_card_model.vhd"
vcom -work work "../bench/incr_encoder_model.vhd"

vcom -work work "${PATH}/hdl/panda_top.vhd"
vcom -work work "../bench/panda_top_tb.vhd"
