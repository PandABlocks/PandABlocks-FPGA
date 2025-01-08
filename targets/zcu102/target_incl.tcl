set FPGA_PART xczu9eg-ffvb1156-2-e
set HDL_TOP zcu102_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            zcu102-pins_impl.xdc \
            zcu102-clks.xdc
}

