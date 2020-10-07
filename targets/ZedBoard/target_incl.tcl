set FPGA_PART xc7z020clg484-1
set BOARD_PART "em.avnet.com:zed:part0:1.3"
set HDL_TOP ZedBoard_top

#set ADDITIONAL_HDL $TARGET_DIR/hdl/*.v

set CONSTRAINTS { \
            ZedBoard-pins_impl.xdc
}
            
