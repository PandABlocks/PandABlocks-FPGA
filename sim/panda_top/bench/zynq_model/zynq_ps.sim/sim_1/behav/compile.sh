#!/bin/sh -f
bin_path="/dls_sw/FPGA/Questa/10.4/questasim/bin"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep source ./zynq_ps_wrapper_compile.do 2>&1 | tee -a compile.log
