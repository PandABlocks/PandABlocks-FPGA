create_ip -vlnv [get_ipdefs -filter {NAME == ila}] -module_name picxo_ila -dir $BUILD_DIR/

set_property -dict [list \
  CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
  CONFIG.C_EN_STRG_QUAL {1} \
  CONFIG.C_INPUT_PIPE_STAGES {2} \
  CONFIG.C_NUM_OF_PROBES {10} \
  CONFIG.C_PROBE0_WIDTH {21} \
  CONFIG.C_PROBE1_WIDTH {22} \
  CONFIG.C_PROBE2_WIDTH {8} \
] [get_ips picxo_ila]

