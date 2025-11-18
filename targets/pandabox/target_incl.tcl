set FPGA_PART xc7z030sbg485-1
set HDL_TOP pandabox_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS {                   \
            pandabox-pins_impl.xdc  \
            pandabox-freq.xdc       \
            pandabox-clks_impl.xdc
}

