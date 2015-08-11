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
ExecStep $bin_path/vsim -64 -c -do "do {zynq_ps_wrapper_simulate.do}" -l simulate.log
