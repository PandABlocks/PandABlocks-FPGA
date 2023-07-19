set FPGA_PART xczu4ev-sfvc784-1-i
set HDL_TOP PandABrick_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            PandABrick-pins_impl.xdc \
            PandABrick-clks.xdc
}

