SEQ - Sequencer
===============================
some description here


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
=============== === ======= ===================================================

Sequencer Frame Composition
---------------------------

=============== ================ ==============================================
Bit Field       Name             Description
=============== ================ ==============================================
[31:0]          Nrepeats         # of repeats for the frame
[35:32]         Input Use        Input bit mask for triggering use
[39:36]         Input Conditions Input conditions to trigger
[45:40]         Phase 1 Outputs  Output values during phase 1
[51:46]         Phase 2 Outputs  Output values during phase 2
[95:64]         Phase 1 Time     Phase 1 length in pre-scaled clock ticks
[127:96]        Phase 2 Time     Phase 2 length in pre-scaled clock ticks
=============== ================ ==============================================

Testing Function Output
----------------------------
This set of tests sets the function value and sees if the output is as expected

.. plot::

    from block_plot import make_block_plot
    make_block_plot("seq", "Test multiple frames and cycles")
