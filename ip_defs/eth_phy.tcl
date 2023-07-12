#
# Create Eth Phy for sfp
#
create_ip -vlnv [get_ipdefs -filter {NAME == gig_ethernet_pcs_pma}] \
-module_name eth_phy -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
    CONFIG.Management_Interface {false} \
    CONFIG.Auto_Negotiation {false} \
    CONFIG.EMAC_IF_TEMAC {TEMAC} \
] [get_ips eth_phy]

