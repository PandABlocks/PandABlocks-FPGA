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
NUM             W   UInt32  Pulse number to be generated
RELATIVE        W   Bit     Relative position compare enable
LUT_ENABLE      W   Bit     Relative position compare LUT mode
ENABLE          In  Bit     | Enable on rising edge
                            | Disable on falling edge
POSN            In  Bit     Position data from position-data bus
ACT             Out Bit     Active output is high while block is in operation
PULSE           Out Bit     Output pulse
TABLE
=============== === ======= ===================================================



Position matching
-----------------
The output pulse will be generated regardless of the direction of the POSN data

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with +ve dir")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Decreasing position with +ve dir")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Decreasing position with -ve dir")

Disable output
--------------
When the ENABLE input is set low the output will cease. This will happen even if
the ENABLE is set low when there are still cycles of the output pulse to
generate, or if the ENABLE = 0 is set at the same time as a position match.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Disable after start")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Disable with start")

Jitter compensation
-------------------
Jitter is ignored if it is below the threshold

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter below FLTR_THOLD")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter below FLTR_THOLD on deltaT edge")

If jitter occurs inside the deltaT window it will be ignored regardless of it's magnitude

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter above FLTR_THOLD inside deltaT")

If jitter above the threshold occurs on deltaT edge, it will disturb the output
until the next deltaT window

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter above FLTR_THOLD on deltaT edge")


If the puse has already started, jitter causing a return to the start value will
not restart the pulse.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter above FLTR_THOLD then return to start")

If the jitter occurs before the start and is above the threshold, the pulse will
be started on the next deltaT window. If the next deltaT windows happens to fall
on the width compare point, the pulses will 'catch up' to the approperiate value

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position with jitter above FLTR_THOLD before start")

If the position is above the start point and the direction filter is positive,
the pulse wont be initiated by a jitter that registers a position increase until
the position goes under the start point and the direction changes to match the
direction filter.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Decreasing from above start with +ve direction filter and direction change above start point")


Error condition
---------------
If at least two compare points are missed, the set the ERROR register and the
outputs will cease.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Pulse is produced after skipping more than 2 compare points")