BITS - Soft inputs and constant bits
====================================

The BITS block contains constants on the bit bus ZERO and ONE, as well as 4
soft values A..D. Each of these soft values can be set to 0 or 1 by using the
SET_A..SET_D parameters.

Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
A               R/W Bit     The value that output A should take
B               R/W Bit     The value that output B should take
C               R/W Bit     The value that output C should take
D               R/W Bit     The value that output D should take
OUTA            Out Bit     The value of A on the bit bus
OUTB            Out Bit     The value of B on the bit bus
OUTC            Out Bit     The value of C on the bit bus
OUTD            Out Bit     The value of D on the bit bus
ZERO            Out Bit     The constant value 0 on the bit bus
ONE             Out Bit     The constant value 1 on the bit bus
=============== === ======= ===================================================

Outputs follow parameters
-------------------------

This example shows how the values on the bit bus follow the parameter values
after a 1 clock tick propogation delay

.. sequence_plot::
   :block: bits
   :title: Outputs follow inputs