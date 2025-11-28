set FPGA_PART xc7z020clg484-1
set HDL_TOP zedboard_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            zedboard-pins_impl.xdc
}

