SRGATE - Set Reset Gate [x4]
============================
some description here


Parameters
----------

=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
FORCE_RESET     W   Action  Reset output to 0
FORCE_SET       W   Action  Set output to 0
SET_EDGE        R/W Enum    | 0 - Sets the output to 1 on rising edge
                            | 1 - Sets the output to 1 on falling edge
RESET_EDGE      R/W Enum    | 0 - Resets the output on rising edge
                            | 1 - Resets the outputon falling edge
SET             In  Bit     A falling/rising edge sets the output to 1
RESET           In  Bit     A falling/rising edge resets the output to 0
VAL             Out Bit     Output value
=============== === ======= ===================================================

Set conditions
----------------------------

some description here

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set on rising Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set on falling Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set on falling Edge with Set")



Reset conditions
----------------

some description here

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Reset on rising Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Reset on falling Edge")

Set-reset conditions
--------------------

some description here

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set-reset conditions")


