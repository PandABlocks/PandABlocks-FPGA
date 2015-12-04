DIV - Pulse divider
===================

There are 4x fully configurable divider blocks. Each block is a 32-bit pulse
divider. It has an internal counter that counts from 0 to DIVISOR-1. On each
user-defined edge, if counter = DIVISOR-1, then it is set to 0 and the pulse is
sent to OUTD, otherwise it is sent to OUTN.

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
INP             In  Bit     Input pulse train
RESET           In  Bit     Reset internal counter state machine on rising edge
OUTD            Out Bit     Divided pulse output
OUTN            Out Bit     Non-divided pulse output
FIRST_PULSE     RW  Enum    | 0 - OutN: Send first pulse to OUTN
                            | 1 - OutD: Send first pulse to OUTD   
DIVISOR         RW  UInt32  Divisor value   
COUNT           R   UInt32  Internal counter value in range [0..DIVISOR-1)
FORCE_RESET     W   Action  Same as RESET
=============== === ======= ===================================================

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("div", "Start on OUTN")

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("div", "Start on OUTD")

.. plot::

    from block_plot import make_block_plot    
    make_block_plot("div", "All")    