.. _framework_reference:

Autogeneration framework architecture
=====================================

Softblocks
----------

Wrappers
--------

How wrapper, config, desc, vhdl entities, test benches are generated

Config_d entries
----------------

.. automodule:: common.python.configs
    :members:

Test benches
------------

A generic outline is common across the testbenches for the different blocks.
There are four main areas of required functionality: Assigning signals, reading
expected data, assigning inputs to the UUT and reading the outputs and comparing
the outputs.

A template can therefore be used to autogenerate the testbench, with this common
functionality, with the modifications required for use with the different
blocks.

Required signals in the block
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Python code used has extracted the different signals which are required from the
``.block.ini`` file for each block. Using this information, register signals are
produced in the testbench for each signal, using the names from the INI file.
However, not all signals are used in the same manner. Therefore the field type
of each signal is also read to determine the size of the required register for
each signals. This is also used to determine whether the signal is an input or
an output signal. Each output signal requires a register signal similar to the
the inputs, however they also require wire signals for use with the UUT, this is
differentiated by the suffix "_UUT" and an error register which is
differentiated by the suffix "_error".

Integer signals are also declared for holding the file identifier, the
``$fscanf`` return value and the timestamp.

Read expected.csv
~~~~~~~~~~~~~~~~~
From the ``.timing.ini`` file within the block, a CSV file is generated which
describes how the UUT should behave under certain inputs at different times. The
first line of the file contains strings with the names of each of the signals,
the first column being the timestamp data. All other lines contain numeric data
for the timestamp, inputs and corresponding outputs.

The file is opened in the testbench and read line by line. The first line,
containing the names of the signals is discarded. The numeric data is then read,
when the timestamp value is equal to that in the file the values are assigned to
the corresponding registers in the testbench. The data in the file is ordered in
the same way as the .block.ini file so iterating through the signals in order,
will assign the data to the correct registers.

Assign signals
~~~~~~~~~~~~~~
The inputs to the entity for the block will have the same name as for those used
in the testbench. It is therefore straightforward to connect the signals. The
registers with the same name as the outputs are being used for holding the
expected values, therefore the wire signals with the suffix "_uut" are used to
read the output signals.

Compare output signals
~~~~~~~~~~~~~~~~~~~~~~
To verify the correct functionality of the block, the outputted values will need
to be compared to the expected values. A simple comparison is implemented, if
the two signals are not equal, set that output's error signal to one and display
an error message to the user.
