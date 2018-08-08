.. _block_reference:

Writing a Block
===============

Rationale behind making a new block

.. _block_ini_reference:

Block ini
---------

How lut_block.ini should be created

The lut_block.ini file can be created with knowledge of the different signals
used within the block.

The first entry to the ini file describes the block as a whole. Under a section:
[.] there should be keys named description and entity with values describing
the purpose of the block and the name of the VHDL entity. The standard notation
is for value to be separated from the key with a colon. For the example of the
LUT block it should appear as follows::

    [.]
    description: Lookup table
    entity: lut


Each signal requires a different section in the ini file. The section name
should be the signal name. There should be keys for type and description with
values describing the type_ and describing the purpose of the signal. If
the data type is an enum the different labels for the different values should be
given. An example for signal A in the LUT
block is given::

    [A]
    type: param enum
    description: Source of the value of A for calculation
    0: Input Value
    1: Rising Edge
    2: Falling Edge
    3: Either Edge

Block VHDL entity
-----------------

How to structure the VHDL entity

Timing ini
----------

Add timing tests

Writing docs
------------

Two RST directives, how to structure


.. _type: :ref:`Field Type <server:fields>`

