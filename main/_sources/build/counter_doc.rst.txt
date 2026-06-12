COUNTER - Up/Down pulse counter
===============================
Each counter block, when enabled, can count up/down with user-defined step value
on the rising edge on input trigger. The counters can also be initialised to a
user-defined START value.

Fields
------

.. block_fields:: modules/counter/counter.block.ini

Counting pulses
---------------

The most common use of a counter block is when you would like to track the
number of trigger edges received while enabled:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Count Up only when enabled

The TRIG_EDGE field can be used to select the track on rising, falling, or both edges:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Setting trigger edge

You can also set the start value to be loaded on enable, and step up by a
number other than one:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Non-zero start and step values

You can also set the direction that a pulse should apply step, so it becomes
an up/down counter. The direction is sampled on the same clock tick as the
pulse edge:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Setting direction

When the OUT_MODE is set to On-Disable, the OUT output will only be changed to
the internal counter value on ENABLE's falling edge:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: On-Disable mode counting


Rollover
--------

If the count goes higher than the max value for an int32 (2147483647) the CARRY
output gets set high and the counter rolls. The CARRY output stays high for as
long as the trigger input stays high.

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Overflow

A similar thing happens for a negative overflow:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Overflow negative

When the OUT_MODE is set to On-Disable, the CARRY output will get set to high
on ENABLE's falling edge if any overflow produced while the counter was enabled:

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: On-Disable mode counting with overflow


Edge cases
----------

If the Enable input goes low at the same time as a trigger, there will be no
output value on the next clock tick.

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Disable and trigger

If the step size is changed at the same time as a trigger input edge,
the output value for that trigger will be the new step size.

.. timing_plot::
   :path: modules/counter/counter_documentation.timing.ini
   :section: Change step and trigger
