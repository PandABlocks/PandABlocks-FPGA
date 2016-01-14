PCOMP - Position Compare [x4]
===============================
description..

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
ENABLE          In  Bit     | Enable on rising edge
                            | Disable on falling edge
POSN            In  Bit     Position data from position-data bus
ACT             Out Bit     Active output is asserted while block is in operation
PULSE           Out Bit     Output pulse
START           W   UInt32  Pulse start position value
STEP            W   UInt32  Pulse step value
WIDTH           W   UInt32  Pulse width value
NUM             W   UInt32  Pulse number to be generated
RELATIVE        W   Bit     Relative position compare enable
LUT_ENABLE      W   Bit     Relative position compare LUT mode
TABLE
=============== === ======= ===================================================



Normal operation
----------------


.. plot::

    from block_plot import make_block_plot
    make_block_plot("pcomp", "Test")