set PLATFORM [lindex $argv 0]
set HWSPEC    [lindex $argv 1]
set DEVTREE_SRC [lindex $argv 2]
set OUTPUT_DIR [lindex $argv 3]

if {$PLATFORM=="zynq"} {
    set PROC ps7_cortexa9_0
    set FSBL_APP zynq_fsbl
} elseif {$PLATFORM=="zynqmp"} {
    set PROC psu_cortexa53_0
    set FSBL_APP zynqmp_fsbl 
} else {
    error "Unknown target platform!"
}

hsi open_hw_design $HWSPEC
hsi generate_app -proc $PROC -app $FSBL_APP -dir $OUTPUT_DIR/fsbl -compile
hsi set_repo_path $DEVTREE_SRC
hsi create_sw_design device_tree -os device_tree -proc $PROC
hsi generate_target -dir $OUTPUT_DIR/dts
if {$PLATFORM=="zynqmp"} {
    hsi generate_app -os standalone -proc psu_pmu_0 -app zynqmp_pmufw \
        -dir $OUTPUT_DIR/pmufw -compile
}
hsi close_hw_design [hsi current_hw_design]

