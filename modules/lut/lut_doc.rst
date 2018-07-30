LUT - 5 Input lookup table
==========================

An LUT block produces an output that is determined by a user-programmable
5-input logic function, set with the FUNC register.


Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
FUNC            R/W UInt32  LUT logic function
A               R/W Enum    | Source of the value of A for calculation
                            | 0 - Input Value
                            | 1 - Rising Edge
                            | 2 - Falling Edge
                            | 3 - Either Edge
B               R/W Enum    Source of the value of B for calculation
C               R/W Enum    Source of the value of C for calculation
D               R/W Enum    Source of the value of D for calculation
E               R/W Enum    Source of the value of E for calculation
INPA            In  Bit     Input A
INPB            In  Bit     Input B
INPC            In  Bit     Input C
INPD            In  Bit     Input D
INPE            In  Bit     Input E
OUT             Out Bit     Output port from the block
=============== === ======= ===================================================

Normal Operation
----------------

The value of FUNC is a 32-bit unsigned int representing the truth table output
of the 5 inputs. The mapping of the string to an integer is done by the
:ref:`PandABlocks TCP server <server:fields>`. The examples below show the
results of some FUNC values.

.. timing_plot:: modules/lut/timing/normal_operation_timing.ini


Changing the function in a test
-------------------------------

If a function is changed, the output will take effect on the next clock tick

.. timing_plot:: modules/lut/timing/changing_function_timing.ini


Edge triggered inputs
---------------------

We can also use the LUT to convert edges into levels by changing A..E to be
one clock tick wide pulses based on edges rather than the current level of
INPA..INPE.

If we wanted to produce a pulse only if INPA had a rising edge on the same clock
tick as INPB had a falling edge we could set FUNC=0xff000000 (A&B) and A=1
(rising edge of INPA) and B=2 (falling edge of INPB):

.. timing_plot:: modules/lut/timing/a_b_edge_timing.ini

We could also use this for generating pulses on every transition of A:

.. timing_plot:: modules/lut/timing/either_edge_timing.ini

