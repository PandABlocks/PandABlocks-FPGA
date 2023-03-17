set FPGA_PART xc7z030sbg485-1
set HDL_TOP PandABox_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS {                   \
            PandABox-pins_impl.xdc  \
            PandABox-freq.xdc       \
            PandABox-clks_impl.xdc
}

# List of IP that can be targeted to this platform.
# NB: these could built as and when required.
set TGT_IP {                        \
            pulse_queue             \
            fifo_1K32               \
            fifo_1K32_ft            \
            fmcgtx                  \
            sfpgtx                  \
            eth_phy                 \
            eth_mac                 \
            system_cmd_fifo         \
            fmc_acq430_ch_fifo      \
            fmc_acq430_sample_ram   \
            fmc_acq427_dac_fifo     \
            ila_32x8K               \
            event_receiver_mgt      \
            sfp_panda_sync          \
            ila_0                   \
            sfp_transmit_mem
}

