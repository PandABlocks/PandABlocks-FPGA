COUNTER  [x8]
=============
Each counter block, when enabled, can count up/down with user-defined step value
on the rising edge on input trigger. The counters can also be initialised to a
user-defined START value.

Fields
------

.. block_fields:: modules/counter/counter.block.ini

Counting pulses
---------------

The most common use of a counter block is when you would like to track the
number of rising edges received while enabled:

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Count Up only when enabled

You can also set the start value to be loaded on enable, and step up by a
number other than one:

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Non-zero start and step values

You can also set the direction that a pulse should apply step, so it becomes
an up/down counter. The direction is sampled on the same clock tick as the
pulse rising edge:

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Setting direction


Rollover
--------

If the count goes higher than the max value for an int32 (2147483647) the CARRY
output gets set high and the counter rolls. The CARRY output stays high for as
long as the trigger input stays high.

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Overflow

A similar thing happens for a negative overflow:

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Overflow negative


Edge cases
----------

If the Enable input goes low at the same time as a trigger, there will be no
output value on the next clock tick.

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Disable and trigger

If the step size is changed at the same time as a trigger input rising edge,
the output value for that trigger will be the new step size.

.. timing_plot::
   :path: modules/counter/counter.timing.ini
   :section: Change step and trigger
