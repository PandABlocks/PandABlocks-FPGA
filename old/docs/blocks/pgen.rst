PGEN - Position Generator [x2]
===============================
The position generator block produces an output position which is pre-defined in
a table

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
CYCLES          W   UInt32  Number of cycles
ENABLE          In  Bit     Halt on falling edge, reset and enable on rising
TRIG            In  Bit     Trigger a sample to be produced
OUT             Out Bit     Current sample
TABLE                       Table of positions to be output
=============== === ======= ===================================================



Normal operation
-----------------
The output pulse will be generated regardless of the direction of the INP data

.. sequence_plot::
   :block: pgen
   :title: Normal operation