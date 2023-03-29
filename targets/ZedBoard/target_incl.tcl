set FPGA_PART xc7z020clg484-1
set BOARD_PART "em.avnet.com:zed:part0:1.3"
set HDL_TOP ZedBoard_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            ZedBoard-pins_impl.xdc
}

# List of IP that can be targeted to this platform.
# NB: these could built as and when required.
set TGT_IP {                        \
            pulse_queue             \
            fifo_1K32               \
            fifo_1K32_ft            \
            eth_phy                 \
            eth_mac                 \
            system_cmd_fifo         \
            fmc_acq430_ch_fifo      \
            fmc_acq430_sample_ram   \
            fmc_acq427_dac_fifo     \
            ila_0
}

