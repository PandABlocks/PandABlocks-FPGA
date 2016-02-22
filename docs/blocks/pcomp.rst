PCOMP - Position Compare [x4]
===============================
The position compare block generates an output pulse, with parameters defined by
WIDTH and STEP, for a pre-configured number of cycles when the position input
value passes a set threshold (defined by the START register). It will generate
this output pulse irrespective of the direction of the position input

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
START           W   UInt32  Pulse start position value
STEP            W   UInt32  Pulse step value
WIDTH           W   UInt32  Pulse width value
PUM             W   UInt32  Pulse number to be generated
RELATIVE        W   Bit     | Relative position compare enable
                            | 0: NO, 1: YES
DIR             W   Bit     Direction of crossing
FLTR_DELTAT     W   UInt32  | Time interval to check if encoder moved more than
                            | FLTR_THOLD
FLTR_THOLD      W   UInt32  | Encoder movement in FLTR_DELTAT to change current
                            | dir
USE_TABLE       W   Bit     Relative position compare LUT mode
ENABLE          In  Bit     | Enable on rising edge
                            | Disable on falling edge
INP             In  Bit     Position data from position-data bus
ACTIVE          Out Bit     Active output is high while block is in operation
OUT             Out Bit     Output pulse
FLTR_DIR        Out Bit     If deltaT > 0 this is the current direction
ERROR           Out Bit     | True if pulse is initiated after at least two
                            | compare ponts
TABLE                       Table of points to use instead of START/STEP/WIDTH
=============== === ======= ===================================================



Position matching
-----------------
The output pulse will be generated regardless of the direction of the INP data

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with +ve dir

.. sequence_plot::
   :block: pcomp
   :title: Decreasing position with +ve dir

.. sequence_plot::
   :block: pcomp
   :title: Decreasing position with -ve dir

Disable output
--------------
When the ENABLE input is set low the output will cease. This will happen even if
the ENABLE is set low when there are still cycles of the output pulse to
generate, or if the ENABLE = 0 is set at the same time as a position match.

.. sequence_plot::
   :block: pcomp
   :title: Disable after start

.. sequence_plot::
   :block: pcomp
   :title: Disable with start

Wait condition
--------------
There will be no output until the input position goes under the DELTAP and
subsequently crosses the START compare point

.. sequence_plot::
   :block: pcomp
   :title: Wait to be below start - DELTAP

Error condition
---------------
If at least two compare points are missed, the set the ERROR register and the
outputs will cease.

.. sequence_plot::
   :block: pcomp
   :title: Error is produced after skipping more than 2 compare points

.. sequence_plot::
   :block: pcomp
   :title: Error skipping multiple compare points

Table usage
-----------
The table provides a list of compare points and widths

.. sequence_plot::
   :block: pcomp
   :title: Table