Glossary
========

This section defines some commonly used PandABlocks terms.

.. _app_:

App
---

An ini file that contains the type and number of Blocks that should be built
together to form an FPGA image (loadable on a PandABlocks device as a `zpkg_`).

.. _block_:

Block
-----

A piece of FPGA logic that has inputs, outputs and parameters, and does
some specified calculations on each FPGA clock tick. It may be a soft Block like
a SEQ, or have hardware connections like a TTLIN Block.

.. _pandabox_:

PandABox
--------

A `pandablocks_device_` manufactured by `Diamond Light Source`_ and `SOLEIL`_.
Schematics on `Open Hardware`_

.. _pandablocks_device_:

PandABlocks Device
------------------

A Zynq 7030 based device loaded with PandABlocks `rootfs`_ so that it runs the
PandABlocks framework.

.. _zpkg_:

Zpkg
----

A specially formatted tar file of built files that can be deployed to a
PandABlocks device




.. _rootfs:
    https://github.com/PandABlocks/PandABlocks-rootfs

.. _Diamond Light Source:
    http://www.diamond.ac.uk

.. _SOLEIL:
    https://www.synchrotron-soleil.fr

.. _Open Hardware:
    https://www.ohwr.org/projects/pandabox/wiki
