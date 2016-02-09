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
START           W   UInt32  Counter start value
STEP            W   UInt32  Up/Down step value
ENABLE          In  Bit     Rising edge enables counter. Falling edge disables
TRIGGER         In  Bit     | Rising edge of trigger input ticks the counter
                            | up/down by a user-defined step value
DIR             In  Bit     Up/Down direction (‘0’=Up Count, ‘1’ = Down Count)
CARRY           Out Bit     Internal counter overflow status
COUNT           Out Pos     Counter output value
=============== === ======= ===================================================

Testing Function Output
----------------------------

.. sequence_plot::
   :block: counter
   :title: Count Up

.. sequence_plot::
   :block: counter
   :title: Count Down

.. sequence_plot::
   :block: counter
   :title: Reverse Count

If the Enable input goes low at the same time as a trigger, there will be no
output value on the next clock tick.

.. sequence_plot::
   :block: counter
   :title: Disable and trigger

If the step size is changed at the same time as a trigger input rising edge,
the output value for that trigger will be the new step size.

.. sequence_plot::
   :block: counter
   :title: Change step and trigger

If the count goes higher than the max value for a uint32 (4294967295) the CARRY
output gets set high.

.. sequence_plot::
   :block: counter
   :title: Overflow