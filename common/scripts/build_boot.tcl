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

puts "open_hw_design start"
hsi open_hw_design $HWSPEC
puts "open_hw_design completed"

puts "generate_app start"
hsi generate_app -proc $PROC -app $FSBL_APP -dir $OUTPUT_DIR/fsbl -compile
puts "generate_app completed"

puts "set_repo start"
hsi set_repo_path $DEVTREE_SRC
puts "set_repo completed"

puts "create_sw_design start"
hsi create_sw_design device_tree -os device_tree -proc $PROC
puts "create_sw_design completed"

puts "generate_target start"
hsi generate_target -dir $OUTPUT_DIR/dts
puts "generate_target completed"

puts "close_hw_design start"
hsi close_hw_design [hsi current_hw_design]
puts "close_hw_design completed"

