SEQ - Sequencer
===============================
The sequencer block performs automatic execution of sequenced lines to produce
timing signals. Each line optionally waits for an external trigger condition and
runs for an optional phase1, then a mandatory phase2 before moving to the next
line. Each line sets the block outputs during phase1 and phase2 as defined by
user-configured mask. Individual lines can be repeated, and the whole table
can be repeated, with a value of 0 meaning repeat forever.

Fields
----------
.. block_fields:: modules/seq/seq.block.ini

Sequencer Table Line Composition
--------------------------------
========= ======== ============================================================
Bit Field Name     Description
========= ======== ============================================================
[15:0]    REPEATS  Number of times the line will repeat
[19:16]   TRIGGER  | The trigger condition to start the phases
                   | 0: Immediate
                   | 1: BITA=0
                   | 2: BITA=1
                   | 3: BITB=0
                   | 4: BITB=1
                   | 5: BITC=0
                   | 6: BITC=1
                   | 7: POSA>=POSITION
                   | 8: POSA<=POSITION
                   | 9: POSB>=POSITION
                   | 10: POSB<=POSITION
                   | 11: POSC>=POSITION
                   | 12: POSC<=POSITION
[63:32]   POSITION The position that can be used in trigger condition
[95:64]   TIME1    The time the optional phase 1 should take
[20:20]   OUTA1    Output A value during phase 1
[21:21]   OUTB1    Output B value during phase 1
[22:22]   OUTC1    Output C value during phase 1
[23:23]   OUTD1    Output D value during phase 1
[24:24]   OUTE1    Output E value during phase 1
[25:25]   OUTF1    Output F value during phase 1
[127:96]  TIME2    The time the mandatory phase 2 should take
[26:26]   OUTA2    Output A value during phase 2
[27:27]   OUTB2    Output B value during phase 2
[28:28]   OUTC2    Output C value during phase 2
[29:29]   OUTD2    Output D value during phase 2
[30:30]   OUTE2    Output E value during phase 2
[31:31]   OUTF2    Output F value during phase 2
========= ======== ============================================================

Generating fixed pulse trains
-----------------------------

The basic use case is for generating fixed pulse trains when enabled. For
example we can ask for 3x 50% duty cycle pulses by writing a single line table
that is repeated 3 times. When enabled it will become active and immediately
start producing pulses, remaining active until the pulses have been produced:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: 3 evenly spaced pulses

We can also use it to generate irregular streams of pulses on different outputs
by adding more lines to the table. Note that OUTB which was high at the end
of Phase2 of the first line remains high in Phase1 of the second line:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Irregular pulses

And we can set repeats on the entire table too. Note that in the second line of
this table we have suppressed phase1 by setting its time to 0:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Table repeats

There are 6 outputs which allow for complex patterns to be generated:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Using all 6 outputs

Statemachine
------------

There is an internal statemachine that controls which phase is currently being
output. It has a number of transitions that allow it to skip PHASE1 if there is
none, or skip WAIT_TRIGGER if there is no trigger condition.

.. digraph:: pcomp_sm

    WAIT_ENABLE [label="State 0\nWAIT_ENABLE"]
    UNREADY [label="State 1\nUNREADY"]
    WAIT_TRIGGER [label="State 2\nWAIT_TRIGGER"]
    PHASE1 [label="State 3\nPHASE1"]
    PHASE2 [label="State 4\nPHASE2"]

    WAIT_ENABLE -> UNREADY [label=" TABLE load started "]
    WAIT_ENABLE -> WAIT_TRIGGER [label=" rising ENABLE and trigger not met "]
    WAIT_ENABLE -> PHASE1 [label=" rising ENABLE and trigger met "]
    WAIT_ENABLE -> PHASE2 [label=" rising ENABLE and trigger met and no phase1 "]

    UNREADY -> WAIT_ENABLE [label=" TABLE load complete "]

    WAIT_TRIGGER -> UNREADY [label=" TABLE load started "]
    WAIT_TRIGGER -> PHASE1 [label=" trigger met "]
    WAIT_TRIGGER -> PHASE2 [label=" trigger met and no phase1 "]

    PHASE1 -> UNREADY [label=" TABLE load started "]
    PHASE1 -> PHASE2 [label=" time1 elapsed "]

    PHASE2 -> UNREADY [label=" TABLE load started "]
    PHASE2 -> WAIT_TRIGGER [label=" next trigger not met "]
    PHASE2 -> PHASE1 [label=" next trigger met "]
    PHASE2 -> PHASE2 [label=" next trigger met and no phase1 "]


External trigger sources
------------------------

The trigger column in the table allows an optional trigger condition to be
waited on before the phased times are started. The trigger condition is checked
on each repeat of the line, but not checked during phase1 and phase2. You can
see when the Block is waiting for a trigger signal as it will enter the
WAIT_TRIGGER(2) state:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Waiting on bit inputs

You can also use a position field as a trigger condition in the same way, this
is useful to do a table based position compare:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Table based position compare


Prescaler
---------

Each row of the table gives a time value for the phases. This value can be
scaled with a block wide prescaler to allow a frame to be longer than
2**32 * 8e-9 = about 34 seconds. For example:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Prescaled pulses


Interrupting a sequence
-----------------------

Setting the repeats on a table row to 0 will cause it to iterate until
interrupted by a falling ENABLE signal:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Infinite repeats of a row interrupted

In a similar way, REPEATS=0 on a table will cause the whole table to be
iterated until interrupted by a falling ENABLE signal:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Infinite repeats of a table interrupted

And a rising edge of the ENABLE will re-run the same table from the start:

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Restarting the same table


Streaming tables
-----------------

When TABLE_LENGTH has the most significant bit set, it indicates there will
be one more table pushed. The condition in which a new table can be pushed
is signaled via an interrupt. When the last table is pushed (indicated by
TABLE_LENGTH's most significant bit cleared), the sequencer will repeat that
table according to the value of the REPEATS register.

.. timing_plot::
   :path: modules/seq/seq_documentation.timing.ini
   :section: Streaming tables
