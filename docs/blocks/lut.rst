LUT - 5 Input lookup table [x8]
===============================
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

Testing Function Output
----------------------------
This set of tests sets the function value and checks whether the output is as
expected

A&B&C&D&E (FUNC= 0x80000000). Setting all inputs to 1
results in an output of 1, and changing any inputs produces an output of 0

.. sequence_plot::
   :block: lut
   :title: A&B&C&D&E Output

~A&~B&~C&~D&~E (FUNC= 0x00000001). Setting all inputs to 0 results
in an output of 1, and changing any inputs produces an output of 0

.. sequence_plot::
   :block: lut
   :title: ~A&~B&~C&~D&~E Output

A (FUNC= 0xffff0000). The output should only be 1 if A is
1 irrespective of any other input.

.. sequence_plot::
   :block: lut
   :title: A output

A&B|C&~D (FUNC= 0xff303030)

.. sequence_plot::
   :block: lut
   :title: A&B|C&~D output

A?(B):D&E (FUNC= 0xff008888)

.. sequence_plot::
   :block: lut
   :title: A?(B):D&E output

Changing the function in a test
-------------------------------
If a function is changed, the output will take effect on the next clock tick

.. sequence_plot::
   :block: lut
   :title: Changing function

Edge triggered inputs
---------------------

We can also use the LUT to convert edges into levels by changing A..E to be
one clock tick wide pulses based on edges rather than the current level of
INPA..INPE.

If we wanted to produce a pulse only if INPA had a rising edge on the same clock
tick as INPB had a falling edge we could set FUNC=0xff000000 (A&B) and A=1
(rising edge of INPA) and B=1 (falling edge of INPB):

.. sequence_plot::
   :block: lut
   :title: Rising A & Falling B

We could also use this for generating pulses on every transition of A:

.. sequence_plot::
   :block: lut
   :title: Either edge A

