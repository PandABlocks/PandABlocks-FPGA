set FPGA_PART xczu4cg-sfvc784-1-e
set HDL_TOP pandabrick_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            pandabrick-pins_impl.xdc \
            pandabrick-clks.xdc
}

