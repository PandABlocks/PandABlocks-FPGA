# INENC - ZMI protocol (Zygo ZMI 4100 serial interface)

With `PROTOCOL = ZMI` an INENC channel receives the serial position output
of a Zygo ZMI 4100 series measurement board (e.g. ZMI 4104). Each ZMI axis
sends its position continuously as a self-timed serial frame. PandA does not
clock the ZMI; it only listens on the encoder data input, checks the Hamming
error correction code of every frame and publishes the position on `VAL`.

Reference: ZMI 4100 Series Measurement Board manual, section 3.6
"Serial Interface", Tables 3-10 to 3-12, and Table 2-5 "P2 Pin Assignments".

ZMI support is currently only built for the PandABox target.

## Wiring

The ZMI serial outputs are LVDS differential pairs on the P2 backplane
connector (rows D and Z). They are wired **directly** to the differential
data input (A / DATA pair) of the PandABox encoder input connectors, one ZMI
axis per INENC channel. No level converter is used.

```text
 ZMI 4104 (P2 connector)                    PandABox rear panel
+---------------------------+               +------------------------+
|  P2D_SERIAL1_P  (D2)  o---+---------------+---o  A+ / DATA+  INENC1 |
|  P2D_SERIAL1_N  (D3)  o---+---------------+---o  A- / DATA-         |
|  GND            (D6)  o---+---------------+---o  GND                 |
|                           |               |                        |
|  P2D_SERIAL2_P  (D4)  o---+---------------+---o  A+ / DATA+  INENC2 |
|  P2D_SERIAL2_N  (D5)  o---+---------------+---o  A- / DATA-         |
|                           |               |                        |
|  P2D_SERIAL3_P  (D7)  o---+---------------+---o  A+ / DATA+  INENC3 |
|  P2D_SERIAL3_N  (D8)  o---+---------------+---o  A- / DATA-         |
|                           |               |                        |
|  P2D_SERIAL4_P  (D9)  o---+---------------+---o  A+ / DATA+  INENC4 |
|  P2D_SERIAL4_N  (D10) o---+---------------+---o  A- / DATA-         |
+---------------------------+               +------------------------+
     LVDS, 40 Mbit/s, one twisted pair per axis, common ground
```

ZMI side, P2D outputs (Table 2-5):

| Axis | Signal | P2 pin | PandABox |
| --- | --- | --- | --- |
| 1 | P2D_SERIAL1_P | D2 | INENC1 A+ / DATA+ |
| 1 | P2D_SERIAL1_N | D3 | INENC1 A- / DATA- |
| 2 | P2D_SERIAL2_P | D4 | INENC2 A+ / DATA+ |
| 2 | P2D_SERIAL2_N | D5 | INENC2 A- / DATA- |
| 3 | P2D_SERIAL3_P | D7 | INENC3 A+ / DATA+ |
| 3 | P2D_SERIAL3_N | D8 | INENC3 A- / DATA- |
| 4 | P2D_SERIAL4_P | D9 | INENC4 A+ / DATA+ |
| 4 | P2D_SERIAL4_N | D10 | INENC4 A- / DATA- |
| - | GND | D6 | GND of each INENC connector |

The same data is also available on row Z (P2Z_SERIAL1..4, pins Z3/Z5,
Z7/Z9, Z11/Z13, Z15/Z17). Either set of outputs can be used; the
corresponding driver must be enabled on the ZMI (see
[ZMI configuration](#inenc-zmi-configuration)).

For the D-type pin numbers of the A+/A-, B+/B-, Z+/Z- and GND pins, see the
PandABox hardware manual. They depend on the fitted encoder daughter card.

Rules for the cable:

- Connect **only** the A / DATA pair and GND. In ZMI mode the FPGA drives the
  B (CLK) and Z pairs of the INENC connector as outputs. They must not be
  connected to any ZMI output.
- Keep P and N together: `_P` to `+`, `_N` to `-`. Swapped polarity inverts
  every bit, and no frame is ever accepted.
- Use one twisted pair per axis, with an impedance of about 100 Ohm, and
  connect the ZMI ground to the PandABox encoder ground.
- LVDS (about 350 mV differential swing, 1.2 V common mode) driving the
  PandABox RS-422 type differential receivers works within the receiver
  thresholds of +/-200 mV. Check that the receiver input on the encoder
  daughter card is terminated (100 to 120 Ohm). LVDS drivers need a
  termination at the receiver end.

## Signal path in the FPGA

```text
Am0 pad --> 2-FF sync --> UART_RX (200 MHz, 5x oversampling)
                              |  48 frame bits
                              v
                          zmi_hamming (3 x Hamming(16,11) SECDED)
                              |  Pos<31:0>, Zmi_err, check result
                              v
                          zmi_master (1 ms link timeout,
                              |       clock domain crossing to 125 MHz)
                              v
                INENC VAL / CONN / HEALTH (BITS, ENCODING, LSB/MSB_DISCARD)
```

- The data input is taken directly from the A pad (`Am0`), before the
  glitch filter that the other protocols use.
- The receiver runs on the 200 MHz PS clock `FCLK_CLK1`. It does **not**
  depend on the `fine_delay` build option.
- The serial clock output (`CLK`) is held low in ZMI mode. The ZMI must
  generate its own sample clock (SCLK0/SCLK1 from the P2 bus or the ZMI
  SCLK timer).
- The encoder daughter card is configured for ZMI by the slow FPGA
  (PandABlocks-slowFPGA, `dcard_ctrl.vhd`, protocol 4).

HDL sources: `common/hdl/encoders/zmi_master.vhd`, `zmi_hamming.vhd`,
`uart_rx.vhd`, `uart_clk_div.vhd`. Testbench:
`tests/sim/zmi/bench/zmi_tb.vhd`, run with Vivado
(`tests/sim/zmi/bench/zmi_tb_compile.tcl`).

## Serial frame format

Only the 32-bit position mode is supported (ZMI Control Register 15,
Serial Data Size = 0). A frame has 50 bits, LSB first, at 40 Mbit/s
(Tables 3-10 and 3-12):

| Frame bits | Contents (in transmission order) | Data bits |
| --- | --- | --- |
| 0 | Start bit (0) | |
| 1 - 16 | Block 1: P1 P2 Pos0 P4 Pos1..3 P8 Pos4..10 Pt | Pos<10:0> |
| 17 - 32 | Block 2: P1 P2 Pos11 P4 Pos12..14 P8 Pos15..21 Pt | Pos<21:11> |
| 33 - 48 | Block 3: P1 P2 Pos22 P4 Pos23..25 P8 Pos26..31 Err Pt | Pos<31:22>, Zmi_err |
| 49 | Stop bit (1) | |

Each 16-bit block is an extended Hamming (16,11) code. P1, P2, P4 and P8
are the Hamming check bits at positions 1, 2, 4 and 8, and Pt is the overall
parity of the block. Per block the receiver:

- corrects any single bit error (also an error in Pt itself);
- detects any double bit error and then discards the whole frame.

Even parity is assumed. If the ZMI uses odd parity, set the generic
`ODD_PARITY => '1'` of `zmi_hamming` in `zmi_master.vhd`.

A missing stop bit is reported in the diagnostic status, but the frame is
still accepted if the Hamming check passes.

The maximum frame rate is 769 kHz (1.30 us period) for 32-bit data
(Table 3-11). The position reaches `VAL` about 1.5 us after the ZMI
samples it: about 230 ns from SCLK to the start bit, 1.25 us for the frame,
and a few clock cycles for checking and the clock domain crossing.

## Block settings

| Field | Setting for ZMI |
| --- | --- |
| PROTOCOL | `ZMI` |
| BITS | 32 |
| ENCODING | `Signed Binary` (ZMI positions are two's complement, the sign bit is the MSB of the P2 Bit Window) |
| LSB_DISCARD | 0, or as needed for scaling |
| MSB_DISCARD | 0 |
| CLK_SRC | `Internally Generated` |
| CLK_PERIOD | not used |
| FRAME_PERIOD | not used (the frame rate is set by the ZMI SCLK) |

Outputs:

- `VAL`: the last position whose Hamming check passed. After a frame with an
  uncorrectable error, or after a link timeout, the previous good value is
  held.
- `CONN`: 1 while the last frame passed the check and `Zmi_err` = 0. It drops
  to 0 when no frame has been received for 1 ms.
- `HEALTH`:

  | Value | Meaning |
  | --- | --- |
  | 0 | OK |
  | 1 | Linkup error: no frame received for 1 ms (or since reset) |
  | 3 | CRC error: the last frame had an uncorrectable (double bit) error |
  | 4 | Error bit active: the ZMI set `Zmi_err`. This is the OR of all reference and measurement errors in the ZMI error status registers (e.g. signal loss) |
  | 6 | Protocol readback error (encoder daughter card mode mismatch) |

  If several conditions apply, the priority is 3, then 1, then 4.

`zmi_master` also has diagnostic status bits and error counters in its
`posn_status_o` output (corrected frames, uncorrectable frames, stop bit
errors, failing block). They are not yet mapped to a register.

(inenc-zmi-configuration)=
## ZMI configuration

Set the following on the ZMI 4104 (see the ZMI manual, chapter 4,
Control Registers 2, 4, 15 and 16):

- **Control Register 15, bit 3** (Serial Data Size) = 0 for 32-bit data.
- **Control Register 15 of axis 3, bit 1** (Serial Output Enable P2D) = 1
  for row D outputs, or **bit 2** (Serial Output Enable P2Z) = 1 for row Z
  outputs. These enable the drivers for all four axes.
- **Control Register 2, bit 8** (Serial Data Enable) = 1 for every axis
  that sends data.
- **Control Register 15, bit 0** (SCLK Serial Sample In) selects whether
  SCLK0 or SCLK1 triggers the serial output. An SCLK must be running, with
  a period of less than 1 ms, otherwise the link timeout reports HEALTH = 1.
  Enable the serial output before starting SCLK.
- **Control Register 4**, P2 Bit Window: selects which 32 bits of the
  internal position word are transmitted, and therefore the scaling of
  `VAL`.
- The SCLK period must be a multiple of 50 ns and at least 1.30 us.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| HEALTH = 1 permanently | No frames: SCLK not running or slower than 1 kHz, serial output or driver not enabled, wrong pair connected, broken cable |
| HEALTH = 3 permanently | Polarity swapped (P/N), 37-bit mode selected on the ZMI, or odd parity (see `ODD_PARITY`) |
| HEALTH = 3 occasionally | Signal integrity: termination, cable length, missing ground connection |
| HEALTH = 4 | ZMI reports a measurement error (check the beam and the ZMI status) |
| VAL changes but has the wrong scale or sign | BITS, ENCODING or ZMI P2 Bit Window |
