LUT - 5 Input lookup table [x8]
===============================
An LUT block produces an output that is determined by a user-programmable
5-input logic function, set with the FUNC register.


Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
FUNC            W   UInt32  LUT logic function
INPA            In  Bit     AddrA input to LUT
INPB            In  Bit     AddrB input to LUT
INPC            In  Bit     AddrC input to LUT
INPD            In  Bit     AddrD input to LUT
INPE            In  Bit     AddrE input to LUT
OUT             Out Bit     Output port from the block
=============== === ======= ===================================================

Testing Function Output
----------------------------
This set of tests sets the function value and checks whether the output is as
expected

A&B&C&D&E (FUNC= 0x80000000 = 2147483648(decimal)). Setting all inputs to 1
results in an output of 1, and changing any inputs produces an output of 0

.. sequence_plot::
   :block: lut
   :title: A&B&C&D&E Output

~A&~B&~C&~D&~E (FUNC= 0x00000001 = 1(decimal)). Setting all inputs to 0 results
in an output of 1, and changing any inputs produces an output of 0

.. sequence_plot::
   :block: lut
   :title: ~A&~B&~C&~D&~E Output

A (FUNC= 0xffff0000 = 4294901760(decimal)). The output should only be 1 if A is
1 irrespective of any other input.

.. sequence_plot::
   :block: lut
   :title: A output

A&B|C&~D (FUNC= 0xffff0000 = 4281348144(decimal))

.. sequence_plot::
   :block: lut
   :title: A&B|C&~D output

A?(B):D&E (FUNC= 0xff008888 = 4278225032(decimal))

.. sequence_plot::
   :block: lut
   :title: A?(B):D&E output

Changing the function in a test
-------------------------------
If a function is changed, the output will take effect on the next clock tick

.. sequence_plot::
   :block: lut
   :title: Changing function