DIV - Pulse divider
===================

A DIV block is a 32-bit pulse divider that can divide a pulse train between two
outputs. It has an internal counter that counts from 0 to DIVISOR-1. On each
rising edge of INP, if counter = DIVISOR-1, then it is set to 0 and the pulse is
sent to OUTD, otherwise it is sent to OUTN. Change in any parameter causes the
block to be reset.

Fields
------

.. block_fields:: modules/div/div.block.ini

Which output do pulses go to
----------------------------

With a DIVISOR of 3, the block will send 1 of 3 INP pulses to OUTD and 2 of 3
INP pulses to OUTN. The following two examples illustrate how the FIRST_PULSE
parameter controls the initial value of OUT, which controls whether OUTD or
OUTN gets the next pulse.

.. timing_plot::
   :path: modules/div/div.timing.ini
   :section: Start on OUTN

.. timing_plot::
   :path: modules/div/div.timing.ini
   :section: Start on OUTD

Reset conditions
----------------

If an ENABLE falling edge is received at the same time as an INP rising edge,
the input signal is ignored and the block reset.


.. timing_plot::
   :path: modules/div/div.timing.ini
   :section: Reset conditions