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
ENABLE          In  Bit     | Enable on rising edge
                            | Disable on falling edge
POSN            In  Bit     Position data from position-data bus
ACT             Out Bit     Active output is high while block is in operation
PULSE           Out Bit     Output pulse
START           W   UInt32  Pulse start position value
STEP            W   UInt32  Pulse step value
WIDTH           W   UInt32  Pulse width value
NUM             W   UInt32  Pulse number to be generated
RELATIVE        W   Bit     Relative position compare enable
LUT_ENABLE      W   Bit     Relative position compare LUT mode
TABLE
=============== === ======= ===================================================



Position matching
----------------
The output pulse will be generated regardless of the direction of the POSN data

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Increasing position")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Decreasing position")

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