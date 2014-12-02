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

