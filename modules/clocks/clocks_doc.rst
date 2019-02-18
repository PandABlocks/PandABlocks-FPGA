CLOCKS - Configurable clocks
============================

The CLOCKS block contains 4 user-settable 50% duty cycle clocks. The period can
be set for each clock separately. When any clock period is set, all clocks
restart from a common synchronous point.

Fields
------

.. block_fields:: modules/clocks/clocks.block.ini

Setting clock period parameters
-------------------------------

Each time a clock parameter is set, the clock restarts from that point with
the new period value.

.. timing_plot::
   :path: modules/clocks/clocks.timing.ini
   :section: Setting a parameter starts clock

All clocks have the same starting point
---------------------------------------

When any period parameter is set, all clocks restart from that point.

.. timing_plot::
   :path: modules/clocks/clocks.timing.ini
   :section: Clocks restart whenever parameter set

Clock settings while disabled
-----------------------------

To start all clocks synchronously you can set then while the Blocks is disabled.
They will all start on rising edge of ENABLE and be zeroed on the falling edge.

.. timing_plot::
   :path: modules/clocks/clocks.timing.ini
   :section: Enable low does not run clocks