#!/usr/bin/sh

VIVADO=/dls_sw/FPGA/Xilinx/Vivado/2022.2

. $VIVADO/settings64.sh

mkdir -p build && cd build

xvhdl ../../../../../common/hdl/sync_bit.vhd &&
xvhdl -2008 ../../sfp_panda_sync_receiver.vhd ../pandaSync_rx_TB.vhd &&
xelab -debug typical pandaSync_rx_TB &&
xsim pandaSync_rx_TB -gui --autoloadwcfg -t ../xsim.tcl

