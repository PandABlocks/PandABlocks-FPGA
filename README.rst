PandABlocks-FPGA
================

|build_status| |readthedocs|

PandABlocks-FPGA contains the firmware that runs on the FPGA inside a Zynq
module that is the heart of a PandABlocks enabled device like PandABox.

Documentation
-------------

Full documentation is available at http://PandABlocks-FPGA.readthedocs.io

Source Code
-----------

Available from https://github.com/PandABlocks/PandABlocks-FPGA

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

License
-------
APACHE License. (see `LICENSE`_)


.. |build_status| image:: https://travis-ci.org/PandABlocks/PandABlocks-FPGA.svg?branch=master
    :target: https://travis-ci.org/PandABlocks/PandABlocks-FPGA
    :alt: Build Status

.. |readthedocs| image:: https://readthedocs.org/projects/PandABlocks-FPGA/badge/?version=latest
    :target: http://PandABlocks-FPGA.readthedocs.org
    :alt: Documentation

.. _CHANGELOG:
    https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/CHANGELOG.rst

.. _CONTRIBUTING:
    https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/CONTRIBUTING.rst

.. _LICENSE:
    https://github.com/PandABlocks/PandABlocks-FPGA/blob/master/LICENSE
