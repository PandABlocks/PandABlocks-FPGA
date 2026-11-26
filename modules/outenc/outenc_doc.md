# OUTENC - Output encoder
The OUTENC block handles the encoder output signals

## Fields

:::{block_fields} modules/outenc/outenc.block.ini
:::

## EnDat

With PROTOCOL set to enDat the block answers EnDat 2.1 "encoder send
position value" requests from an external master with VAL, BITS bits at a
time, followed by the CRC. GENERATOR_ERROR sets the error bit of the answer.
Other mode commands are ignored. Like an EnDat encoder the block holds the
half duplex data line low while idle, releases it for the master's mode
command and drives it again for its answer. HEALTH reports a timeout if the
master stops its clock in the middle of a frame.
