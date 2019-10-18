Running the tests
=================

There are a number of different test systems in place within the
PandABlocks-FPGA directory. There are python tests to check the output of some
of the Jinja2 templates, python tests to check the logic of the timing diagram
and then there are hdl testbenches which test the functionality of the blocks.
The python tests are ran as part of the Travis tests when a commit is made to
the git repository, however the hdl testbenches have to be manually ran.

Python tests
~~~~~~~~~~~~
The first of the python tests, checking the output of the Jinja2 templates, can
be run from the Makefile.
    make python_tests

The python simulation tests, can be run with the following Makefile command.
    make python_timing

HDL tests
~~~~~~~~~

There are two Makefile functions which can be used to run the hdl testbenches.
    make hdl_test (MODULE="module name")

    make single_hdl_test TEST="MODULE_NAME TEST_NUMBER"

The first, by default, will run every testbench. However if the optional
argument of MODULE is given it will instead run every test for the specified
module. Please note that the module name is the entity name for the top level
hdl filein that module.

The second command will run a single testbench as specified by the module name,
and the test number separated by a space.
