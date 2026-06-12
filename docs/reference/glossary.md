# Glossary

FPGA-specific terms are defined in the canonical PandABlocks glossary in the
meta-panda docs. Common terms used across this repo:

```{glossary}
App
: A collection of {term}`block` instances specified in an `.app.ini` file that
  can be built into an FPGA image (an `.ipk` package) and loaded onto a
  PandABlocks device.

Block
: A piece of FPGA logic with a number of {term}`field` instances that performs
  calculations each FPGA clock tick. May be a soft block (e.g. SEQ) or have
  hardware connections (e.g. TTLIN).

Field
: An input, output, or parameter of a {term}`block`.

Module
: A directory containing block definitions, logic, simulations, and timing.
  Modules typically contain a single soft block definition, or a number of
  hardware blocks tied to a particular target platform, SFP, or FMC card.

PandABox
: A PandABlocks device manufactured by Diamond Light Source and SOLEIL.
  Schematics on [Open Hardware](https://www.ohwr.org/projects/pandabox/wiki).

PandABlocks device
: A Zynq 7030-based device loaded with the PandABlocks rootfs and firmware.

Target platform
: The physical Zynq-based hardware (e.g. PandABox, Picozed Carrier) that is
  loaded with firmware to become a PandABlocks device.

Zpkg
: A specially formatted tar archive of built files that can be deployed to a
  PandABlocks device (legacy pre-5.0 format; replaced by opkg `.ipk` packages
  from 5.0 onwards).
```

:::{seealso}
The full canonical glossary (including web-control terms) lives in the
meta-panda docs at `reference/glossary`.
:::
