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

A piece of FPGA logic that has a number of `field_` instances and does some
specified calculations on each FPGA clock tick. It may be a soft
Block like a SEQ, or have hardware connections like a TTLIN Block.

.. _field_:

Field
-----

An input, output or parameter of a `block_`.

.. _module_:

Module
------

A directory containing `block_` definitions, logic, simulations and timing.
Modules will typically contain a single soft Block definition, or a number of
hardware Blocks tied to a particular `target_paltform_`, `SFP`_ or `FMC`_ card.

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

.. _target_platform_:

Target Platform
---------------

The physical Zynq based hardware that will be loaded with firmware to
become a `pandablocks_device_` like a `pandabox_` or a `Picozed Carrier`_

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

.. _Picozed Carrier:
    http://zedboard.org/product/picozed-fmc-carrier-card-v2

.. _SFP:
    https://en.wikipedia.org/wiki/Small_form-factor_pluggable_transceiver

.. _FMC:
    https://en.wikipedia.org/wiki/FPGA_Mezzanine_Card