.. include:: <s5defs.txt>

.. |emdash| unicode:: U+02014 .. EM DASH
.. |bullet| unicode:: U+02022


==========================
Building Core PandA Rootfs
==========================

:Author: Michael Abbott
:Date: 3rd May 2016

Most of this presentation is condensed from the readme file for the
``zebra2-rootfs`` project.


PandA Rootfs
============

The project ``zebra2-rootfs`` on Github builds the following:

* Files required to boot PandA.  These are the files that go into the initial SD
  card image::

    boot.bin    devicetree.dtb     uEnv.txt  uinitramfs
    config.txt  imagefile.cpio.gz  uImage

* Kernel build.  This is required by the ``zebra2-server`` in order to build the
  kernel driver.


Built Files
===========

======================= ========================================================
``boot.bin``            Loaded by zero stage boot loader
``uEnv.txt``            Instructions to U-Boot
``devicetree.dtb``      Hardware description needed by kernel
``uImage``              Linux kernel
``uinitramfs``          Initial file system and startup script
``imagefile.cpio.gz``   Target root file system
``config.txt``          Default network configuration
======================= ========================================================

These are placed in the root of a clean SD card to create a bootable system.


Build Dependencies
==================

The following must be installed before building this project:

* Xilinx Zynq SDK.

* U-Boot and Linux kernel sources.  This project requires the Xilinx branches of
  these projects.

* The Diamond rootfs builder.  This can be downloaded from
  https://github.com/araneidae/rootfs.  The current build needs at least version
  1.7.

* Sources needed for rootfs build.  These can now be downloaded from the Github
  release page, or from their respective project repositories.


Configuring ``CONFIG.local``
============================

Copy the file ``CONFIG.example`` to ``CONFIG.local`` and modify the following
fields as required:

``ZEBRA2_ROOT``:
    This is where the entire build occurs.  At least 2GB of storage must be free
    in this area.

``TAR_FILES``:
    All of the source files require to build the system will be looked for in
    this directory.  This can also be a list of directories if necessary.

``SDK_ROOT``:
    Location of the Xilinx SDK that will be used to build the system.

``ROOTFS_TOP``:
    This needs to point to the root directory of the Diamond rootfs builder,
    download from the github location given above.


Building
========

Type::

    make

The build takes around half an hour, and the results will be placed in
``$(ZEBRA2_ROOT)/boot``.
