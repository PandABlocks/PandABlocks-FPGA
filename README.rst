PandABlocks-FPGA
================

|code_ci| |docs_ci| |license|

PandABlocks-FPGA contains the firmware that runs on the FPGA inside a Zynq
module that is the heart of a PandABlocks enabled device like PandABox.

============== ==============================================================
Source code    https://github.com/PandABlocks/PandABlocks-FPGA
Documentation  https://PandABlocks.github.io/PandABlocks-FPGA
Changelog      https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/CHANGELOG.rst
============== ==============================================================


Installation
------------

You need to define a CONFIG file with some variables in it. The simplest is
to copy CONFIG.example and edit it. After this type::

    make

to build the zpkgs for all apps. More information in the documentation.

Changelog
---------

See `CHANGELOG`_

Contributing
------------

See `CONTRIBUTING`_

.. |code_ci| image:: https://github.com/PandABlocks/PandABlocks-FPGA/workflows/Code%20CI/badge.svg?branch=master
    :target: https://github.com/PandABlocks/PandABlocks-FPGA/actions?query=workflow%3A%22Code+CI%22
    :alt: Code CI


.. |docs_ci| image:: https://github.com/PandABlocks/PandABlocks-FPGA/workflows/Docs%20CI/badge.svg?branch=master
    :target: https://github.com/PandABlocks/PandABlocks-FPGA/actions?query=workflow%3A%22Docs+CI%22
    :alt: Docs CI

.. |license| image:: https://img.shields.io/badge/License-Apache%202.0-blue.svg
    :target: https://opensource.org/licenses/Apache-2.0
    :alt: Apache License

.. _CHANGELOG:
    https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/CHANGELOG.rst

.. _CONTRIBUTING:
    https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/CONTRIBUTING.rst

See https://PandABlocks.github.io/PandABlocks-FPGA for more detailed documentation
