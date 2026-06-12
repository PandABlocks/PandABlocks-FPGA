SRGATE - Set Reset Gate
=======================

An SRGATE block produces either a high (SET) or low (RST) output. It has
configurable inputs and an option to force its output independently. Both Set
and Rst inputs can be selected from bit bus, and the active-edge of its
inputs is configurable. An enable signal allows the block to ignore its inputs.


Fields
----------
.. block_fields:: modules/srgate/srgate.block.ini

Normal conditions
-----------------

The normal behaviour is to set the output OUT on the configured edge of the
SET or RESET input.

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Set on rising Edge

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Set on falling Edge

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Set on either Edge RST default

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Reset on rising Edge

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Reset on falling Edge

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Reset on either Edge SET falling

Disabling the block
-------------------
The default behaviour is to force the block output low when disabled, ignoring
any SET/RST events:

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Output low while disabled

The disabled value can also be set high:

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Output high while disabled

Or left at its current value:

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Output left at current while disabled

Active edge configure conditions
--------------------------------
if the active edge is 'rising' then reset to 'falling' at the same time as a
rising edge on the SET input, the block will ignore the rising edge and set
the output OUT on the falling edge of the SET input.

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Rising SET with SET_EDGE reconfigure

If the active edge changes to 'falling'  at the same time as a falling edge
on the SET input, the output OUT will be set following this.

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Falling SET with SET_EDGE reconfigure

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Falling RST with with reset edge reconfigure

Set-reset conditions
--------------------

When determining the output if two values are set simultaneously, FORCE_SET and
FORCE_RESET registers take priority over the input bus, and reset takes priority
over set.

.. timing_plot::
   :path: modules/srgate/srgate.timing.ini
   :section: Set-reset conditions
