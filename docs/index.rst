PandABlocks-FPGA
================

PandABlocks-FPGA contains the firmware that runs on the FPGA inside a Zynq
module that is the heart of a PandABlocks enabled device like PandABox.

What can PandABlocks do?
------------------------

PandABlocks is a framework enabling a number of functional Blocks to be written
and loaded to an FPGA, with the connections between them and their parameters
changed at runtime. It allows flexible triggering and processing systems to
be created, by users who are unfamiliar with writing FPGA firmware.

How is the documentation structured?
------------------------------------

The documentation is structured into a series of `tutorials_doc` and some
general `reference_doc` documentation. End users and developers need different
documentation, so links for various categories of user are listed below:

Using an existing PandABlocks device
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Work through the `tutorials_doc`.

Generating a new set of Blocks for a PandABlocks device
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Read the `blocks_doc` to find the available Blocks, then read
`apps_reference` to see how to make an App of these Blocks that can be loaded
to a PandABlocks device.

Making a new Block
~~~~~~~~~~~~~~~~~~

Read the `blocks_doc` to see if you need to create a new Block or add to
an existing one. Read the `block_ini_reference` to find out how to specify the
interface to a Block, and `vhdl_guidelines_reference` to find out how to
structure your Block entity in VHDL.
