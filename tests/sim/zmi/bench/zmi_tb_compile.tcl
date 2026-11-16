set TOP [lindex $argv 0]
set BUILD_DIR [lindex $argv 1]
set MODE [lindex $argv 2]

create_project zmi_tb $BUILD_DIR/build/tests/zmi_tb -force -part xc7z030sbg485-1

set_property top zmi_tb [current_fileset -simset]
add_files $TOP/common/hdl/defines/support.vhd
add_files [list \
    $TOP/common/hdl/encoders/uart_clk_div.vhd \
    $TOP/common/hdl/encoders/uart_rx.vhd \
    $TOP/common/hdl/encoders/zmi_hamming.vhd \
    $TOP/common/hdl/encoders/zmi_master.vhd]
add_files $TOP/tests/sim/zmi/bench
set_property FILE_TYPE "VHDL 2008" [get_files *.vhd]

launch_simulation
restart
run -all
