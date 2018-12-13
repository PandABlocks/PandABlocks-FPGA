.. _app_reference:

Assembling Blocks into an App
=============================

A collections of `block_` instances that can be loaded to a
`pandablocks_device_` is called an `app_`. This section details how to create
and build a new App.

App ini file
------------

An ini file is used to specify the Blocks that make up an App. It lives in the
``apps/`` directory and has the extension ``.app.ini``. It consists of a top
level section with information about the App, then a section for every `block_`
in the App.

The [.] section
~~~~~~~~~~~~~~~

The first section contains app wide information. It looks like this:

.. code-block:: ini

    [.]
    description: Short description of what this app will do
    target: device_type

The ``description`` value is a human readable description of what the app
contains and why it should be used.

The ``target`` value must correspond to a directory name in ``targets/`` that
will be used to wrap the blocks in a top level entity that is loadable on the
given PandABlocks device.

[BLOCK] sections
~~~~~~~~~~~~~~~~

All other sections specify Block instance information. They look like this:

.. code-block:: cfg

    [MYBLOCK]
    number: 4
    module: mymodule
    ini: myblock.block.ini

The section name is used to determine the name of the Block in the resulting
App. It should be made of upper case letters and underscores with no numbers.

The ``number`` value gives the number of blocks that will be instantiated in the
App. If not specified it will default to 1.

The ``module`` value gives the directory in ``modules/`` that the
`block_ini_reference` file lives in. If not specified it is the lowercase
version of the section name.

The ``ini`` value gives the `block_ini_reference` filename relative to the
module directory. If not specified it is the lowercase version of the section
name + ``.block.ini``

App build process
-----------------

Run::

    make

And it will make a `zpkg_` for each App that can be loaded onto the PandABlocks
Device. You can specify a subset of Apps to be built in the top level CONFIG
file by specifying something like::

    APPS = PandABox-no-fmc
