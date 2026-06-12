CLOCK - Configurable clock
==========================

The CLOCK block contains a user-settable clock with parametable width and period.

Fields
------

.. block_fields:: modules/clock/clock.block.ini

Setting clock period parameters
-------------------------------

Each time a clock width or period parameter is set, the clock restarts from that point with
the new width and period value.

.. timing_plot::
   :path: modules/clock/clock.timing.ini
   :section: Setting a parameter starts clock

The clock is disabled when both width and period parameters are set to 0.
If period is smaller or egale to width then it'll be adjusted to (width + 1) and at least to 2.
If width=0, then the clock duty-cycle will be 50%:

.. timing_plot::
   :path: modules/clock/clock.timing.ini
   :section: Run clock with WIDTH and PERIOD parameters

Clock settings while disabled
-----------------------------

To start the clock synchronously you can set them while the Block is disabled.
It will start on rising edge of ENABLE and be zeroed on the falling edge.

.. timing_plot::
   :path: modules/clock/clock.timing.ini
   :section: Enable low does not run clocks