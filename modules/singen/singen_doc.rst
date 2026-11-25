SINGEN - Sine Wave Generator
=============================

The SINGEN block is a sine wave synthesizer. 

This is a discrete time implementation, with 1 MHz fixed sampling frequency: the same of the FMC_ACQ427 analog card block.

Full scale is meant to be +/- 1 in the scaled PandaBlocks representation (or signed 32-bit int if raw representation is preferred).

It can generate a sine wave with frequency in range [0.1 Hz, 500 kHz]

Based on Xilinx DDS Compiler v6.0.


-----------------------------------------------------
Fields
-----------------------------------------------------

.. block_fields:: modules/singen/singen.block.ini










