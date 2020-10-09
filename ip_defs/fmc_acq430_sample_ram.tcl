#
# Create low level ACQ430 FMC Sample RAM
#
create_ip -vlnv [get_ipdefs -filter {NAME == dist_mem_gen}] \
-module_name fmc_acq430_sample_ram -dir $BUILD_DIR/

set_property -dict [list \
        CONFIG.depth {32} \
        CONFIG.data_width {24} \
        CONFIG.memory_type {dual_port_ram} \
        CONFIG.output_options {registered} \
        CONFIG.common_output_clk {true}
] [get_ips fmc_acq430_sample_ram]

generate_target all [get_files $BUILD_DIR/fmc_acq430_sample_ram/fmc_acq430_sample_ram.xci]
synth_ip [get_ips fmc_acq430_sample_ram]
