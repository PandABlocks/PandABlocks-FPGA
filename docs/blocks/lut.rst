LUT - 5 Input lookup table [x4]
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

Set conditions
----------------------------

some description here

.. plot::

    from block_plot import make_block_plot
    make_block_plot("lut", "Change inputA")



