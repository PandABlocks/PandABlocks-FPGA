BITS - Soft inputs and constant bits
====================================

The BITS block contains 4 soft values A..D. Each of these soft values can be set
to 0 or 1 by using the SET_A..SET_D parameters.

Fields
------

.. block_fields:: modules/bits/bits.block.ini

Outputs follow parameters
-------------------------

This example shows how the values on the bit bus follow the parameter values
after a 1 clock tick propagation delay

.. timing_plot::
   :path: modules/bits/bits.timing.ini
   :section: Outputs follow inputs