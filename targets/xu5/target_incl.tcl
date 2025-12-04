set FPGA_PART xczu4ev-sfvc784-1-i
set HDL_TOP xu5_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            xu5-pins_impl.xdc \
            xu5-clks.xdc
}

