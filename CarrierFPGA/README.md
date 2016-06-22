------------------------------------------------------------------------
-- PandA FPGA/SoC Build for Panda-Motion Project
--
-- Contact:
--      Dr. Isa Uzun,
--      Diamond Light Source Ltd,
--      Diamond House,
--      Chilton,
--      Didcot,
--      Oxfordshire,
--      OX11 0DE
--      isa.uzun@diamond.ac.uk
------------------------------------------------------------------------

Makefile has following steps:

  Step 1. Zynq PS Block design and exports HDF file
  Step 2. Zynq Top level design bit file
  Step 3. Gets device-tree BSP sources (remote git or local tarball)
  Step 4. Generates xsdk project (using xml configuration file)
  Step 5. Generates fsbl elf, and device-tree dts files
  Step 6. Generates devicetree.dtb file and copies to TFTP server


Each step is referenced in the Makefile as a reference.


NOTES:

A. OPERATIONAL NOTES
--------------------
i. Mounting work directory

    $ mount 172.23.100.32:/exports/dls_sw/work /mnt/work


B. DEVICETREE
--------------------
i. system.mss
    A manual .mss file is used to configure devicetree bsp version (2015.1) in xsdk.

ii. panda_pcap IP
    Position capture IP is taken out of the Block Design, so its configuration
is manually added in the system-top.dts file.
    IMPORTANT :Baseaddress, address range and IRQ number may need to be modified accordingy.

C. IRQ SETTING for DEVICETREE
------------------------------

The device tree declaration goes something like (copied from above):

      interrupts = < 0 59 1 >;
      interrupt-parent = <&gic>;

So what are these three numbers assigned to “interrupt”?

The first number (zero) is a flag indicating if the interrupt is an SPI (shared
peripheral interrupt). A nonzero value means it is an SPI. The truth is that
these interrupts are SPIs according to Zynq’s Technical Reference Manual (the
TRM), and still the common convention is to write zero in this field, saying
that they aren’t. Since this misdeclaration is so common, it’s recommended to
stick to it, in particular since declaring the interrupt as an SPI will cause
some confusion regarding the interrupt number. This is discussed in detail here.

The second number is related to the interrupt number. To make a long story
short, click the “GIC” box in XPS’ main window’s “Zynq” tab, look up the number
assigned to the interrupt (91 for xillybus in Xillinux) and subtract it by 32
(91 - 32 = 59).

IMPORTANT : The third number is the type of interrupt. Three values are possible:

    0 — Leave it as it was (power-up default or what the bootloader set it to,
if it did)
    1 — Rising edge
    4 — Level sensitive, active high

Other values are not allowed. That is, falling edge and active low are not
supported, as the hardware doesn’t support those modes. If you need these, put a
NOT gate in the logic.

It’s notable that the third number is often zero in “official” device trees, so
the Linux kernel leaves the interrupt mode to whatever it was already set to.
This usually means active high level triggering, and still, this makes the Linux
driver depend on that the boot loader didn’t mess up.

Finally, the interrupt-parent assignment. It should always point to the
interrupt controller, which is referenced by &gic. On device trees that were
reverse compiled from a DTB file, a number will appear instead of this
reference, typically 0x1.
