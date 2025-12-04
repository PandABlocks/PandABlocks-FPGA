set FPGA_PART xczu6cg-ffvc900-1-e
set HDL_TOP pandabox2_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            pandabox2-pins_impl.xdc
}

