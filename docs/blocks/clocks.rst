CLOCKS - Configurable clocks
============================

The CLOCKS block contains 4 user-settable 50% duty cycle clocks. The period can
be set for each clock separately. When any clock period is set, all clocks 
restart from a common synchronous point.

Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
A_PERIOD        R/W Time    The period of clock output A, 0 or 1 = off
B_PERIOD        R/W Time    The period of clock output B, 0 or 1 = off
C_PERIOD        R/W Time    The period of clock output C, 0 or 1 = off
D_PERIOD        R/W Time    The period of clock output D, 0 or 1 = off
A               Out Bit     The current value of clock A
B               Out Bit     The current value of clock B
C               Out Bit     The current value of clock C
D               Out Bit     The current value of clock D
=============== === ======= ===================================================

Setting clock period parameters
-------------------------------

Each time a clock parameter is set, the clock restarts from that point with
the new period value.

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("clocks", "Setting a parameter starts clock")
    
All clocks have the same starting point
---------------------------------------

When any period parameter is set, all clocks restart from that point.

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("clocks", "Clocks restart whenever parameter set")

