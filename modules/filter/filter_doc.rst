FILTER - Filter
========================

The filter block has two different modes of operation: Difference and Average.
They both work by latching the values on the input and performing an operation
comparing to the current value.

Fields
------

.. block_fields:: modules/filter/filter.block.ini

Difference
----------------------------

The difference operation works by latching the value on the input on the rising
edge of the Enable signal. On a rising edge of the trigger signal the output is
given as the the current input value minus the latched value.


.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Difference mode

After the operation, the latched value is updated to be the current value on
the input.

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Difference mode positive ramping input

The operation continues to work if the current value is less than the latched
value: a negative result is outputted

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Difference mode negative ramping input

Average
----------------

The average function appends a sum value on each clock pulse. When a trigger
signal is received it divides the summed value by the number of clock pulses
that have passed.

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Average mode summing inputs

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Average mode positive ramp

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Average mode negative ramp

If a calculation is triggered before the calculation is ready, the system will
show an error on the HEALTH output and will then need to be re-enabled before
another calculation can be sent.

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Average mode trigger before calculation ready

.. timing_plot::
   :path: modules/filter/filter_documentation.timing.ini
   :section: Zero division
