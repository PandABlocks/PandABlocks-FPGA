Contributing
============

Contributions and issues are most welcome! All issues and pull requests are
handled through github on the `PandABlocks repository`_. Also, please check for
any existing issues before filing a new one. If you have a great idea but it
involves big changes, please file a ticket before making a pull request! We
want to make sure you don't spend your time coding something that might not fit
the scope of the project.

.. _PandABlocks repository: https://github.com/PandABlocks/PandABlocks-FPGA/issues

Running the tests
-----------------

To get the source source code and run the unit tests, run::

    $ git clone git://github.com/PandABlocks/PandABlocks-FPGA.git
    $ cd PandABlocks-FPGA
    $ virtualenv venv
    $ source venv/bin/activate
    $ pip install --upgrade pip
    $ pip install -r tests/requirements.txt
    $ cp CONFIG.example CONFIG
    $ make test_python
    $ make sim_timing

Code Styling
------------

VHDL
====

Code styling here...


Python
======

Please arrange imports with the following style

.. code-block:: python

    # Standard library imports
    import os

    # Third party package imports
    from mock import patch

    # Local package imports
    from common.python.configs import BlockConfig

Please follow `Google's python style`_ guide wherever possible.

.. _Google's python style: https://google.github.io/styleguide/pyguide.html

Building the docs
-----------------

When in the project directory::

    $ source venv/bin/activate
    $ pip install -r docs/requirements.txt
    $ make docs
    $ firefox docs/index.html


Release Checklist
-----------------

Before a new release, please go through the following checklist:

* Add a release note in CHANGELOG.rst
* Git tag the version

