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

Jitter compensation
-------------------
Jitter is ignored if it is below the threshold

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter below FLTR_THOLD

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter below FLTR_THOLD on deltaT edge

If jitter occurs inside the deltaT window it will be ignored regardless of it's magnitude

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter above FLTR_THOLD inside deltaT

If jitter above the threshold occurs on deltaT edge, it will disturb the output
until the next deltaT window

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter above FLTR_THOLD on deltaT edge

If the puse has already started, jitter causing a return to the start value will
not restart the pulse.

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter above FLTR_THOLD then return to start

If the jitter occurs before the start and is above the threshold, the pulse will
be started on the next deltaT window. If the next deltaT windows happens to fall
on the width compare point, the pulses will 'catch up' to the approperiate value

.. sequence_plot::
   :block: pcomp
   :title: Increasing position with jitter above FLTR_THOLD before start

If the position is above the start point and the direction filter is positive,
the pulse wont be initiated by a jitter that registers a position increase until
the position goes under the start point and the direction changes to match the
direction filter.

.. sequence_plot::
   :block: pcomp
   :title: Decreasing from above start with +ve direction filter and direction change above start point

Error condition
---------------
If at least two compare points are missed, the set the ERROR register and the
outputs will cease.

.. sequence_plot::
   :block: pcomp
   :title: Error is produced after skipping more than 2 compare points
