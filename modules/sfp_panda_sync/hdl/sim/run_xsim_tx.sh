#!/usr/bin/sh

VIVADO=/dls_sw/FPGA/Xilinx/Vivado/2022.2

. $VIVADO/settings64.sh

mkdir -p build && cd build

xvhdl ../../../../../common/hdl/sync_bit.vhd &&
xvhdl -2008 ../../sfp_panda_sync_transmit.vhd ../pandaSync_tx_TB.vhd &&
xelab -debug typical pandaSync_tx_TB &&
xsim pandaSync_tx_TB -gui --autoloadwcfg -t ../xsim.tcl

