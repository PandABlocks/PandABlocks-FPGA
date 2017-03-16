INENC - Input encoder
=====================
The INENC block handles the encoder input signals

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
PROTOCOL        R/W Enum    | 0 - Protocol type = Quadrature
                            | 1 - Protocol type = SSI
                            | 2 - Protocol type = BISS
                            | 3 - Protocol type = enDat
CLK_PERIOD      W   UInt32  Clock rate
FRAME_PERIOD    W   UInt32  Frame rate
BITS            W   UInt63  Number of bits
SETP            In  Pos     Set point
RST_ON_Z        W   Bit     Zero position on Z rising edge
STATUS          R   Enum    | 0 - Encoder status = All OK
                            | 1 - Encoder status = Link Down
                            | 2 - Encoder status = Encoder Error
                            | 3 - Encoder status = Link Down and Error
DCARD+MODE      R           Daughter card jumper mode
A               Out Bit     Quadrature A if in incrememtal mode
B               Out Bit     Quadrature B if in incremental mode
Z               Out Bit     Z index channel if in incremental mode
CONN            Out Bit     Signal detected
TRANS           Out Bit     Position transition
VAL             Out Pos     Current position
=============== === ======= ===================================================



