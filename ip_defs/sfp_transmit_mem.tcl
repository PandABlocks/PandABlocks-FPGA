#
# Create Memory
create_ip -vlnv [get_ipdefs -filter {NAME == blk_mem_gen}] \
-module_name sfp_transmit_mem -dir $BUILD_DIR/

set_property -dict [list                                                            \
    CONFIG.Write_Depth_A {4096}                                                     \
    CONFIG.Operating_Mode_A {READ_FIRST}                                            \
    CONFIG.Load_Init_File {true}                                                    \
    CONFIG.Coe_File $TOP/tests/sim/sfp_receiver/mem/event_receiver_mem.coe \
    CONFIG.Use_RSTA_Pin {false}                                                     \
] [get_ips sfp_transmit_mem]

