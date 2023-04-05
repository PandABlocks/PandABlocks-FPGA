#
# Create ILA IP (32-bit wide with 8K Depth)
#
create_ip -vlnv [get_ipdefs -filter {NAME == ila}] \
-module_name ila_32x8K -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.C_PROBE0_WIDTH {32}  \
    CONFIG.C_DATA_DEPTH {8192}  \
] [get_ips ila_32x8K]

