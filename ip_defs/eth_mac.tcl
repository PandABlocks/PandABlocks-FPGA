#
# Create Eth Mac for sfp
#

create_ip -vlnv [get_ipdefs -filter {NAME == tri_mode_ethernet_mac}] \
-module_name eth_mac -dir $BUILD_DIR/


#shared logic inside of core
# CONFIG.Physical_Interface {GMII} \ phy_eth is internal (no IOB or idelay in pad) CONFIG.Physical_Interface {Internal}

set_property -dict [list \
    CONFIG.Physical_Interface {Internal} \
    CONFIG.MAC_Speed {1000_Mbps}         \
    CONFIG.Management_Interface {false}  \
    CONFIG.Management_Frequency {125.00} \
    CONFIG.Enable_Priority_Flow_Control {false} \
    CONFIG.Frame_Filter {false}          \
    CONFIG.Number_of_Table_Entries {0}   \
    CONFIG.Enable_MDIO {false}           \
    CONFIG.SupportLevel {1}              \
    CONFIG.Make_MDIO_External {false}    \
    CONFIG.Statistics_Counters {false}   \
] [get_ips eth_mac]

generate_target all [get_files $BUILD_DIR/eth_mac/eth_mac.xci]
synth_ip [get_ips eth_mac]

