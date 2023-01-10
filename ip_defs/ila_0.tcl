#
# Create ILA chipscope
create_ip -vlnv [get_ipdefs -filter {NAME == ila}] \
-module_name ila_0 -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.C_DATA_DEPTH {2048}  \
    CONFIG.C_PROBE7_WIDTH {32}  \
    CONFIG.C_PROBE6_WIDTH {6}   \
    CONFIG.C_PROBE5_WIDTH {32}  \
    CONFIG.C_PROBE4_WIDTH {32}  \
    CONFIG.C_PROBE3_WIDTH {32}  \
    CONFIG.C_PROBE2_WIDTH {32}  \
    CONFIG.C_PROBE1_WIDTH {32}  \
    CONFIG.C_PROBE0_WIDTH {32}  \
    CONFIG.C_NUM_OF_PROBES {8}  \
    CONFIG.C_TRIGOUT_EN {false} \
    CONFIG.C_TRIGIN_EN {false}  \
] [get_ips ila_0]

generate_target all [get_files $BUILD_DIR/ila_0/ila_0.xci]

