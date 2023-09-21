## Create PICXO IP

create_ip -vlnv [get_ipdefs -filter {NAME == PICXO_FRACXO}] -module_name PICXO_FRACXO -dir $BUILD_DIR/

set_property CONFIG.GT_TYPE {GTX} [get_ips PICXO_FRACXO]

