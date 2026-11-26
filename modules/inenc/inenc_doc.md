# INENC - Input encoder
The INENC block handles the encoder input signals

## Fields

:::{block_fields} modules/inenc/inenc.block.ini
:::

## EnDat

With PROTOCOL set to enDat the block is an EnDat master. Every FRAME_PERIOD
it sends the EnDat 2.1 "encoder send position value" mode command, which
EnDat 2.2 encoders also answer, clocking at CLK_PERIOD, and reads back BITS
position bits (the 32 least significant are kept), the error bit and the
CRC. HEALTH reports a timeout when the encoder does not answer, a CRC error
or the error bit being set, and VAL only updates on a good frame. The error
bit F1 is taken as low active, as Heidenhain encoders send it; the
F1_ERROR_VALUE generic of the EnDat entities selects the other convention.

The EnDat data line is half duplex. The encoder holds it low while idle and
the master only starts a frame once it reads low, so a missing encoder is
reported as a timeout. The master drives the line for the mode command only
and leaves it to the encoder for the rest of the frame.

The encoder changes its data after the rising edge of the clock and the
master samples it shortly after the falling edge. For long cables, where the
round trip delay approaches half a clock period, DELAY_COMP delays the
sampling point by that many FPGA clock ticks (8 ns each).

On an Encoder Monitor daughter card the block instead decodes the position
from the frames of an external EnDat master connected to the monitored
encoder. The error bit is ignored there, the external master deals with it,
so HEALTH only reports timeouts and CRC errors.
