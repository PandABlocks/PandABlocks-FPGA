OUTENC - Output encoder
=======================
The OUTENC block handles the encoder output signals

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
PROTOCOL        R/W Enum    | 0 - Protocol type = Quadrature
                            | 1 - Protocol type = SSI
                            | 2 - Protocol type = BISS
                            | 3 - Protocol type = enDat
BITS            W   UInt63  Number of bits
Q_PERIOD        W   UInt32  Quadrature prescaler
ENABLE          W   BIT     Halt on falling edge, reset and enable on rising
A               Out Bit     Input for A (only straight through)
B               Out Bit     Input for B (only straight through)
Z               Out Bit     Input for Z (only straight through)
VAL             Out Pos     Input for position (all other protocols)
CONN            Out Bit     Input for connected
QSTATE          R   Enum    | 0 - Quadrature state = Disabled
                            | 1 - Quadrature state = At position
                            | 2 - Quadrature state = Slewing
=============== === ======= ===================================================

