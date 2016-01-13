COUNTER  [x8]
=============
Each counter block, when enabled, can count up/down with user-defined step value
on the rising edge on input trigger. The counters can also be initialised to a
user-defined START value.

Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
ENABLE          In  Bit     Enable on Rising edge; Disabl e on falling edge
TRIGGER         In  Bit     | Rising edge of trigger input ticks the counter
                            | up/down by a user-defined step value
DIR             In  Bit     Up/Down direction (‘0’=Up Count, ‘1’ = Down Count)
COUNT           Out Pos     Counter output value
CARRY           Out Bit     Internal counter overflow status
START           W   UInt32  Counter start value
STEP            W   UInt32  Up/Down step value
=============== === ======= ===================================================

Testing Function Output
----------------------------

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Count Up")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Count Down")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Reverse Count")

If the Enable input goes low at the same time as a trigger, there will be no
output value on the next clock tick.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Disable and trigger")


If the step size is changed at the same time as a trigger input rising edge,
the output value for that trigger will be the new step size.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Change step and trigger")

If the count goes higher than the max value for a uint32 (4294967295) the CARRY
output gets set high.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("counter", "Overflow")