set FPGA_PART xc7z030sbg485-1
set BOARD_PART "em.avnet.com:picozed_7030:part0:1.0"
set HDL_TOP PandABox_top
#set ADDITIONAL_HDL 

set CONSTRAINTS { \
                PandABox-pins_impl.xdc \
                PandABox-freq.xdc \
                PandABox-clks_impl.xdc
}
