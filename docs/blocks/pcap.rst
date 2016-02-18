PCAP - Position Capture
=======================

<<description>>


Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
ENABLE          In  Bit     Data capture enable
FRAME           In  Bit     Data capture frame
CAPTURE         In  Bit     Data capture event
ERR_STATUS      R   UInt32  Block error status
ACTIVE          Out Bit     Data capture in progress
CAPTURE_TS                  Timestamp of captured data
FRAME_LENGTH                Length of captured frame
CAPTURE_OFFSET              Offset of capture into capture frame
ADC_COUNT                   Number of ADC samples in captured frame
BITS0                       Quadrant 0 of bit_bus
BITS1                       Quadrant 1 of bit_bus
BITS2                       Quadrant 2 of bit_bus
BITS3                       Quadrant 3 of bit_bus
=============== === ======= ===================================================

Arming
------

.. sequence_plot::
   :block: pcap
   :title: Arming and soft disarm

.. sequence_plot::
   :block: pcap
   :title: Arming and hard disarm

Timestamp capture
-----------------
.. sequence_plot::
   :block: pcap
   :title: capture timestamp

If there are capture signals too close together, the ERR_STATUS will be set to 2

.. sequence_plot::
   :block: pcap
   :title: capture too close together

Pos bus and bit bus capture
---------------------------

Capturing from the TTLIN will capture from quadrant1, SEQ from quadrant 2,
COUNTER from quadrant 3, and INEC from quadrant 4. The order these results are
output from the block is Q1, Q2, Q3, Q4.

.. sequence_plot::
   :block: pcap
   :title: capture pos bus enc1

.. sequence_plot::
   :block: pcap
   :title: capture bit bus TTLIN

.. sequence_plot::
   :block: pcap
   :title: capture bit bus SEQ

.. sequence_plot::
   :block: pcap
   :title: capture bit bus order

Framing
-------

The framing can be in two modes, difference mode or average mode.
In difference mode, the output is the difference between the current capture
point value and the last value in the previous frame. In average mode, the
output is the mean value of the current capture point value and the last value
in the previous frame.

.. sequence_plot::
   :block: pcap
   :title: framing on counters

.. sequence_plot::
   :block: pcap
   :title: framing on counters average mode

.. sequence_plot::
   :block: pcap
   :title: Capture offset

An error will be encounted if there is a capture signal before the first frame,
or if there are more than one capture signals per frame.

.. sequence_plot::
   :block: pcap
   :title: Capture before first frame

.. sequence_plot::
   :block: pcap
   :title: More than one capture within a frame