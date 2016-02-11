DIV - Pulse divider [x4]
========================

A DIV block is a 32-bit pulse divider that can divide a pulse train between two
outputs. It has an internal counter that counts from 0 to DIVISOR-1. On each
rising edge of INP, if counter = DIVISOR-1, then it is set to 0 and the pulse is
sent to OUTD, otherwise it is sent to OUTN. Change in any parameter causes the
block to be reset.

Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
DIVISOR         R/W UInt32  Divisor value
FIRST_PULSE     R/W Enum    | 0 - OutN: Send first pulse to OUTN
                            | 1 - OutD: Send first pulse to OUTD
FORCE_RESET     W   Action  Reset internal counter state machine
INP             In  Bit     Input pulse train
RESET           In  Bit     On rising edge, reset counter state machine
OUTD            Out Bit     Divided pulse output
OUTN            Out Bit     Non-divided pulse output
COUNT           R   UInt32  Internal counter value in range [0..DIVISOR-1)
=============== === ======= ===================================================

Which output do pulses go to
----------------------------

With a DIVISOR of 3, the block will send 1 of 3 INP pulses to OUTD and 2 of 3
INP pulses to OUTN. The following two examples illustrate how the FIRST_PULSE
parameter controls the initial value of COUNT, which controls whether OUTD or
OUTN gets the next pulse.

.. sequence_plot::
   :block: div
   :title: Start on OUTN

.. sequence_plot::
   :block: div
   :title: Start on OUTD

Reset conditions
----------------

If a RESET rising edge, or a FORCE_RESET parameter write is received at the same
time as an INP rising edge, the input signal is ignored and the block reset. It
makes no difference where the falling edge of the RESET comes.

.. sequence_plot::
   :block: div
   :title: Reset conditions

