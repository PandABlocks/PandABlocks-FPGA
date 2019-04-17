CLOCK - Configurable clock
==========================

The CLOCK block contains a user-settable 50% duty cycle clock.

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

Clock settings while disabled
-----------------------------

To start the clock synchronously you can set them while the Block is disabled.
It will start on rising edge of ENABLE and be zeroed on the falling edge.

.. timing_plot::
   :path: modules/clocks/clocks.timing.ini
   :section: Enable low does not run clocks