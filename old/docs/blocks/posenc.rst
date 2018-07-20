POSENC - Quadrature and step/direction encoder
==============================================
The POSENC block handles the Quadrature and step/direction encoding

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
INP             IN          Zero position on Z rising edge
QPERIOD         W   Pos     Set point
ENABLE          In          Halt on falling edge, reset and enable on rising
PROTOCOL        R/W Enum    | 0 - Quadrature
                            | 1 - Step/Direction
A               Out Bit     Quadrature A/Step output
B               Out Bit     Quadrature B/Direction output
QSTATE          R   Enum    | 0 - Quadrature output state = Disabled
                            | 1 - Quadrature output state = At position
                            | 2 - Quadrature output state = Slewing
=============== === ======= ===================================================

