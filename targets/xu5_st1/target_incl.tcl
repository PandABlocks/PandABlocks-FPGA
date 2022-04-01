set FPGA_PART xczu4ev-sfvc784-1-i
set HDL_TOP xu5_st1_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            xu5_st1-pins_impl.xdc
}

# List of IP that can be targeted to this platform.
# NB: these could built as and when required.
set TGT_IP {                        \
            pulse_queue             \
            fifo_1K32               \
            fifo_1K32_ft            \
            fmc_acq430_ch_fifo      \
            fmc_acq430_sample_ram
}

