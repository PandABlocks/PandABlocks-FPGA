#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/dls_sw/apps/FPGA/Xilinx/SDK/2015.1/bin:/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/ids_lite/ISE/bin/lin64:/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/bin
else
  PATH=/dls_sw/apps/FPGA/Xilinx/SDK/2015.1/bin:/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/ids_lite/ISE/bin/lin64:/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/ids_lite/ISE/lib/lin64
else
  LD_LIBRARY_PATH=/dls_sw/apps/FPGA/Xilinx/Vivado/2015.1/ids_lite/ISE/lib/lin64:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD=`dirname "$0"`
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log pulse_queue.vds -m64 -mode batch -messageDb vivado.pb -notrace -source pulse_queue.tcl
