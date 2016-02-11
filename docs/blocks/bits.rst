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
A_SET           R/W Bit     The value that output A should take
B_SET           R/W Bit     The value that output B should take
C_SET           R/W Bit     The value that output C should take
D_SET           R/W Bit     The value that output D should take
A               Out Bit     The value of A_SET on the bit bus
B               Out Bit     The value of B_SET on the bit bus
C               Out Bit     The value of C_SET on the bit bus
D               Out Bit     The value of D_SET on the bit bus
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