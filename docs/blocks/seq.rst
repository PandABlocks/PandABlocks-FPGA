SEQ - Sequencer
===============================
The sequencer block performs automatic execution of sequenced frames to produce
timing signals. Each frame is started internally or by external trigger and
runs for the user-defined time frame (phase-1) and waits for dead time (phase-2)
before moving to the next frame. Each frame sets the block outputs during
phase-1 and phase-2 as defined by user-configured mask.

The frame starts in a wait phase, where it waits until the configured inputs
meet the configured input conditions. Once these input conditions are met,
phase-1 begins and runs for its configured duration, after this, phase22 begins
and runs for its configured duration. If a frame is set to repeat, the repeat
cycle will set outputs immediately, provided the inputs meet the input
conditions.

The procedure for writing table data is to first write to TABLE_RESET, then
sequentially write four 32 bit values to TABLE_DATA. TABLE_STROBES can be read
to ensure that it matches the number of writes to TABLE_DATA. After a complete
table has been written, the TABLE_LENGTH must be provided. After a TABLE_RST, a
whole table and table length must be provided; this means that you cannot
partially overwrite a table. The TABLE_RST sets the ACTIVE state to 0 and
once the TABLE_LENGTH is provided, if the GATE is high, the ACTIVE state is
reset to 1 and the sequencer starts from the beginning of the table.

Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
GATE            In  Bit     | Gate input:
                            | - Rising edge: Starts the sequencer state machine
                            | - Falling edge: Stops the state machine and puts
                            |   it into FINISHED state
INPA            In  Bit     Trigger input A
INPB            In  Bit     Trigger input B
INPC            In  Bit     Trigger input C
INPD            In  Bit     Trigger input D
OUTA            Out Bit     Blocak output A
OUTB            Out Bit     Blocak output B
OUTC            Out Bit     Blocak output C
OUTD            Out Bit     Blocak output D
OUTE            Out Bit     Blocak output E
OUTF            Out Bit     Blocak output F
ACTIVE          Out Bit     Sequencer Active Flag
PRESCALE        W   UInt32  Prescalar for system clock
TABLE_LENGTH    W   Uint16  Number of frames in the table
SOFT_GATE       W   Bit     Soft Gate pulse
CUR_FRAME       R   UInt32  | Sequencer current frame number value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
CUR_FCYCLE      R   UInt32  | Sequencer current frame cycle value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
CUR_TCYCLE      R   UInt32  | Sequencer current table cycle value. 0 in
                            | INACTIVE state, 1 indexed in ACTIVE state.
TABLE_STROBES   R   UInt32  Number of times data has been written to the table
TABLE_CYCLE     W   UInt32  Number of cycles for the table
TABLE_RST       W   UInt32  | Resets table write address to the beginning of the
                            | table
TABLE_DATA      W   UInt32  Table data to be pushed sequentially to the buffer
TABLE_WSTB      W   UInt32  Number of times data has been written to the table
=============== === ======= ===================================================

Sequencer Frame Composition
---------------------------

=============== ================ ==============================================
Bit Field       Name             Description
=============== ================ ==============================================
[31:0]          Nrepeats         Number of repeats(cycles) for the frame
[35:32]         Input Use        Input bit mask for triggering use
[39:36]         Input Conditions Input conditions to trigger
[45:40]         Phase 1 Outputs  Output values during phase 1
[51:46]         Phase 2 Outputs  Output values during phase 2
[95:64]         Phase 1 Time     Phase 1 length in pre-scaled clock ticks
[127:96]        Phase 2 Time     Phase 2 length in pre-scaled clock ticks
=============== ================ ==============================================

Normal operation
----------------
Once a table has been written, and the table length provided, the GATE input
sets the sequencer in the ACTIVE state. The sequencer cycles through frames and
waits for inputs to meet the pre-configured input requirements before setting
outputs in phase-1 and phase2

TABLE_DATA
~~~~~~~~~~~

FRAME 1

================ ======================
Field            Value
================ ======================
REPEATS           1
INPUT MASK        F
INPUT CONDITIONS  F
PHASE 1 OUTPUTS   01 (OUTA)
PHASE 2 OUTPUTS   3F
PHASE 1 LENGTH    2*PRESCALE
PHASE 2 LENGTH    1*PRESCALE
================ ======================

FRAME 2

================ ======================
Field            Value
================ ======================
REPEATS           2
INPUT MASK        F
INPUT CONDITIONS  E (INPB, INPC, INPD)
PHASE 1 OUTPUTS   3F
PHASE 2 OUTPUTS   02 (OUTB)
PHASE 1 LENGTH    3*PRESCALE
PHASE 2 LENGTH    2*PRESCALE
================ ======================

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Multiple frames, multiple frame and table cycles")

Inputs outside of active state
------------------------------
Table data must be written after a write to TABLE_RST, which sets the active
state to 0. This means that any inputs that are received during a table write
action are ignored. Similarly, when the sequencer finishes all frame and table
cycles, it sets the active state to 0, thus any inputs after this will be
ignored.

TABLE_DATA
~~~~~~~~~~~

FRAME 1

================ ======================
Field            Value
================ ======================
REPEATS           1
INPUT MASK        F
INPUT CONDITIONS  F
PHASE 1 OUTPUTS   01 (OUTA)
PHASE 2 OUTPUTS   3F
PHASE 1 LENGTH    2*PRESCALE
PHASE 2 LENGTH    1*PRESCALE
================ ======================

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Writing inputs before a whole frame is written")

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Writing inputs after sequencer has finished")

Sequencer and table reset
-------------------------
If the sequencer is set to an inactive state, and then reset to active, the
sequencer will start from the beginning of the table.

TABLE_DATA
~~~~~~~~~~~

FRAME 1

================ ======================
Field            Value
================ ======================
REPEATS           1
INPUT MASK        F
INPUT CONDITIONS  F
PHASE 1 OUTPUTS   01 (OUTA)
PHASE 2 OUTPUTS   3F
PHASE 1 LENGTH    2*PRESCALE
PHASE 2 LENGTH    1*PRESCALE
================ ======================

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Setting inactive before finished and restarting")


A table reset and data write must provide a whole table. If a table is currently
written with multiple frames, and a table reset and write overwrites the table
with less frames, only the new table will be executed. It is not possible to
partially overwrite a table.

TABLE_DATA
~~~~~~~~~~~

TABLE 1, FRAME 1

================ ======================
Field            Value
================ ======================
REPEATS           1
INPUT MASK        F
INPUT CONDITIONS  F
PHASE 1 OUTPUTS   01 (OUTA)
PHASE 2 OUTPUTS   3F
PHASE 1 LENGTH    2*PRESCALE
PHASE 2 LENGTH    1*PRESCALE
================ ======================

TABLE 1, FRAME 2

================ ======================
Field            Value
================ ======================
REPEATS           2
INPUT MASK        F
INPUT CONDITIONS  E (INPB, INPC, INPD)
PHASE 1 OUTPUTS   3F
PHASE 2 OUTPUTS   02 (OUTB)
PHASE 1 LENGTH    3*PRESCALE
PHASE 2 LENGTH    2*PRESCALE
================ ======================

TABLE 2, FRAME 1

================ ======================
Field            Value
================ ======================
REPEATS           1
INPUT MASK        1
INPUT CONDITIONS  1  (INPA)
PHASE 1 OUTPUTS   04 (OUTC)
PHASE 2 OUTPUTS   08 (OUTD)
PHASE 1 LENGTH    1*PRESCALE
PHASE 2 LENGTH    2*PRESCALE
================ ======================

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Reset table and write more data")
