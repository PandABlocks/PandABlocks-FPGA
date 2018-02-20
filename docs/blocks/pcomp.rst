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
START           W   Pos     Pulse start position value
STEP            W   Pos     Pulse step value
WIDTH           W   Pos     Pulse width value
PNUM            W   UInt32  Pulse number to be generated
RELATIVE        W   Bit     | Relative position compare enable
                            | 0: Absolute, 1: Relative
DIR             W   Bit     | Direction of crossing
                            | 0: Positive, 1: Negative
DELTAP          W   Pos     | INP must be this far away from START in -DIR before
                            | input starts being monitored for compare points
ENABLE          In  Bit     | Enable on rising edge
                            | Disable on falling edge
INP             In  Bit     Position data from position-data bus
ACTIVE          Out Bit     Active output is high while block is in operation
OUT             Out Bit     Output pulse
ERROR           Out Enum    | 0: OK
                            | 1: Position jumped by more than STEP
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

