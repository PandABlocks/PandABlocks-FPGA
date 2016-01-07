LUT - 5 Input lookup table [x8]
===============================
some description here


Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
INPA            In  Bit     AddrA input to LUT
INPB            In  Bit     AddrB input to LUT
INPC            In  Bit     AddrC input to LUT
INPD            In  Bit     AddrD input to LUT
INPE            In  Bit     AddrE input to LUT
VAL             Out Bit     Output port from the block
FUNC            W   UInt32  LUT logic function
=============== === ======= ===================================================

Testing Function Output
----------------------------
This set of tests sets the function value and sees if the output is as expected

A&B&C&D&E (FUNC= 0x80000000 = 2147483648(decimal)). Setting all inputs to 1 results in an output of 1, and changing any results in an output of 0

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "A&B&C&D&E Output")


~A&~B&~C&~D&~E (FUNC= 0x00000001 = 1(decimal)). Setting all inputs to 0 results in an output of 1, and changing any results in an output of 0

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "~A&~B&~C&~D&~E Output")


A (FUNC= 0xffff0000 = 4294901760(decimal)). The output should only be 1 if A is 1 irrespective of any other input.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "A output")

A&B|C&~D (FUNC= 0xffff0000 = 4281348144(decimal))

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "A&B|C&~D output")


A?(B):D&E (FUNC= 0xff008888 = 4278225032(decimal))

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "A?(B):D&E output")