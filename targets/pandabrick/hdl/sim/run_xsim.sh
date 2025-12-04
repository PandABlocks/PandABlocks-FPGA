#!/usr/bin/sh

VIVADO=/dls_sw/FPGA/Xilinx/Vivado/2022.2

. $VIVADO/settings64.sh

mkdir -p build && cd build

xvlog $VIVADO/data/verilog/src/glbl.v ../../Adaptor_PIC_SPI.v &&
xvhdl ../Adaptor_PIC_SPI_tb.vhd &&
xelab -L unisims_ver -debug typical Adaptor_PIC_SPI_tb glbl &&
xsim work.Adaptor_PIC_SPI_tb#work.glbl -gui --autoloadwcfg -t ../xsim.tcl

