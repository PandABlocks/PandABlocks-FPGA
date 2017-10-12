PCOMP - Position Compare [x4]
=============================

The position compare block takes a position input and allows a regular number
of threshold comparisons to take place on a position input. The normal order
of operations is something like this:

* If PRE_START > 0 then wait until position has passed START - PRE_START
* If START > 0 then wait until position has passed START and set OUT=1
* Wait until position has passed START + WIDTH and set OUT=0
* Wait until position has passed START + STEP and set OUT=1
* Wait until position has passed START + STEP + WIDTH and set OUT=0
* Continue until PULSES have been produced

It can be used to generate a position based pulse train against an input encoder
or analogue system, or to work as repeating comparator.


Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
PRE_START       RW  Pos     INP must be this far from START before waiting for START
START           RW  Pos     Pulse absolute/relative start position value
WIDTH           RW  Pos     The relative distance between a rising and falling edge
STEP            RW  Pos     The relative distance between successive rising edges
PULSES          RW  UInt32  The number of pulses to produce, 0 means infinite
RELATIVE        RW  Enum    | If 1 then START is relative to the position of INP at enable
                            | * 0: Absolute
                            | * 1: Relative
DIR             RW  Enum    | Direction to apply all relative offsets to
                            | - 0: Positive
                            | - 1: Negative
                            | - 2: Either
ENABLE          In  Bit     Stop on falling edge, reset and enable on rising edge
INP             In  Pos     Position data from position-data bus
ACTIVE          Out Bit     Active output is high while block is in operation
OUT             Out Bit     Output pulse train
HEALTH          R   Enum    | 0: OK
                            | 1: Error: Position jumped by more than STEP
PRODUCED        R   UInt32  The number of pulses produced
STATE           R   Enum    | The internal statemachine state
                            | - 0: WAIT_ENABLE
                            | - 1: WAIT_PRE_START
                            | - 2: WAIT_START
                            | - 3: WAIT_WIDTH
                            | - 4: WAIT_STEP
=============== === ======= ===================================================


Position compare is directional
-------------------------------

A typical example would setup the parameters, enable the block, then start
moving a motor to trigger a series of pulses:

.. sequence_plot::
   :block: pcomp
   :title: 3 Pulses in a +ve direction

But if we get the direction wrong, we won't get the first pulse until we cross
START in the correct direction:

.. sequence_plot::
   :block: pcomp
   :title: Enabled while crossing in wrong direction

Moving in a negative direction works in a similar way. Note that WIDTH and
PULSE still have positive values:

.. sequence_plot::
   :block: pcomp
   :title: 2 Pulses in a -ve direction

We can also ask to the Block to calculate direction for us:

.. sequence_plot::
   :block: pcomp
   :title: Calculate direction to be -ve

.. sequence_plot::
   :block: pcomp
   :title: Calculate direction to be +ve

Internal statemachine
---------------------

The Block has an internal statemachine that is exposed as a parameter, allowing
the user to see what the Block is currently doing:

.. digraph:: pcomp_sm

    WAIT_ENABLE [label="State 0\nWAIT_ENABLE"]
    WAIT_DIR [label="State 1\nWAIT_DIR"]
    WAIT_PRE_START [label="State 2\nWAIT_PRE_START"]
    WAIT_RISING [label="State 3\nWAIT_RISING"]
    WAIT_FALLING [label="State 4\nWAIT_FALLING"]

    WAIT_ENABLE -> WAIT_DIR [label=" rising ENABLE & DIR=EITHER "]
    WAIT_ENABLE -> WAIT_PRE_START [label=" rising ENABLE "]

    WAIT_DIR -> WAIT_ENABLE [label=" Can't guess DIR \n or Disabled "]
    WAIT_DIR -> WAIT_PRE_START [label=" DIR calculated "]
    WAIT_DIR -> WAIT_FALLING [label=" DIR calculated no PRE_START"]

    WAIT_PRE_START -> WAIT_ENABLE [label=" Disabled "]
    WAIT_PRE_START -> WAIT_RISING [label=" < PRE_START "]

    WAIT_RISING -> WAIT_ENABLE [label=" jump > WIDTH + STEP \n or Disabled "]
    WAIT_RISING -> WAIT_FALLING [label=" >= pulse "]

    WAIT_FALLING -> WAIT_ENABLE [label=" jump > WIDTH + STEP \n or Finished \n or Disabled"]
    WAIT_FALLING -> WAIT_RISING [label=" >= pulse + WIDTH "]

Not generating a pulse more than once
-------------------------------------

A key part of position compare is not generating a pulse at a position more
than once. This is to deal with noisy encoders:

.. sequence_plot::
   :block: pcomp
   :title: Only produce pulse once

This means that care is needed if using direction sensing or relying on the
directionality of the encoder when passing the start position. For example,
if we approach START from the negative direction while doing a positive
position compare, then jitter back over the start position, we will generate
start at the wrong place. If you look carefully at the statemachine you will
see that the Block crossed into WAIT_START when INP < 4 (START), which is too
soon for this amount of jitter:

.. sequence_plot::
   :block: pcomp
   :title: Jittering over the start position

We can fix this by adding to the PRE_START deadband which the encoder has to
cross in order to advance to the WAIT_START state. Now INP < 2 (START-PRE_START)
is used for the condition of crossing into WAIT_START:

.. sequence_plot::
   :block: pcomp
   :title: Avoiding jitter problem with PRE_START


Interrupting a scan
-------------------

When the ENABLE input is set low the output will cease. This will happen even if
the ENABLE is set low when there are still cycles of the output pulse to
generate, or if the ENABLE = 0 is set at the same time as a position match.

.. sequence_plot::
   :block: pcomp
   :title: Disable after start

.. sequence_plot::
   :block: pcomp
   :title: Disable with start


Position compare on absolute values
-----------------------------------

Doing position compare on an absolute value adds additional challenges, as
we are not guaranteed to see every transition. It works in much the same
way as the previous examples, but we trigger on greater than or equal rather
than just greater than:

.. sequence_plot::
   :block: pcomp
   :title: Absolute Pulses in a +ve direction


But what should the Block do if the output is 0 and the position jumps by
enough to trigger a transition to 1 and then back to 0? We handle this by
setting HEALTH="Error: Position jumped by more than STEP" and aborting
the compare:

.. sequence_plot::
   :block: pcomp
   :title: Error skipping when OUT=0

Likewise if the output is 1 and the position causes us to need to produce a 0
then 1:

.. sequence_plot::
   :block: pcomp
   :title: Error skipping when OUT=1

And if we skipped a larger number of points we get the same error:

.. sequence_plot::
   :block: pcomp
   :title: Error is produced after skipping more than 2 compare points


Relative position compare
-------------------------

We may want to nest position compare blocks, or respond to some external event.
In which case, we expose the option to a position compare relative to the
latched position at the start:

.. sequence_plot::
   :block: pcomp
   :title: Relative position compare

We can also guess the direction in relative mode:

.. sequence_plot::
   :block: pcomp
   :title: Guess relative direction +ve

And with a PRE_START value we guess the direction to be the opposite to the
direction the motor is travelling when it exceeds PRE_START:

.. sequence_plot::
   :block: pcomp
   :title: Guess relative direction +ve with PRE_START


We cannot guess the direction when RELATIVE mode is set with no START or
PRE_START though, the Block will error in this case:

.. sequence_plot::
   :block: pcomp
   :title: Guess relative direction with no START

