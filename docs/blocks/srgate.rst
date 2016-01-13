SRGATE - Set Reset Gate [x4]
============================
An SRGATE block produces either a high (SET) or low (RESET) output. It has
configurable inputs and an option to force its output independently.Both Set
and Reset inputs can be selected from system bus, and the active-edge of its
inputs is configurable


Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
SET             In  Bit     A falling/rising edge sets the output to 1
RESET           In  Bit     A falling/rising edge resets the output to 0
VAL             Out Bit     Output value
SET_EDGE        R/W Enum    | 0 - Sets the output to 1 on rising edge
                            | 1 - Sets the output to 1 on falling edge
RESET_EDGE      R/W Enum    | 0 - Resets the output on rising edge
                            | 1 - Resets the outputon falling edge
FORCE_RESET     W   Action  Reset output to 0
FORCE_SET       W   Action  Set output to 0
=============== === ======= ===================================================

Normal conditions
-----------------

The normal behaviour is to set the output VAL on the configured edge of the
SET or RESET input.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set on rising Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set on falling Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Reset on rising Edge")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Reset on falling Edge")



Active edge configure conditions
--------------------------------
if the active edge is 'rising' then reset to 'falling' at the same time as a
rising edge on the SET input, the block will ignore the rising edge and set
the output VAL on the falling edge of the SET input.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Rising SET input with SET_EDGE reconfigure")

If the active edge changes to 'falling'  at the same time as a falling edge
on the SET input, the output VAL will be set following this.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Falling SET input wtih SET_EDGE reconfigure")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate",
        "Falling RESET input with with reset edge reconfigure")



Set-reset conditions
--------------------

When determining the output if two values are set simultaneously, the input bus
takes priority over registers, and reset takes priority over set.

.. plot::

    from block_plot import make_block_plot
    make_block_plot("srgate", "Set-reset conditions")
