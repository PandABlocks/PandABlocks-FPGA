PCAP - Position Capture
=======================

Position capture has the capability to capture anything that is happening
on the pos_bus or bit_bus. It listens to ENABLE, GATE and CAPTURE signals, and
can capture the value at capture, sum, min and max.


Fields
----------

.. block_fields:: targets/PandABox/blocks/pcap/pcap.block.ini

Arming
------

To start off the block an arm signal is required with a write to ``*PCAP.ARM=``.
The active signal is raised immediately on ARM, and dropped either on
``*PCAP.DISARM``:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Arming and soft disarm

Or on the falling edge of ENABLE:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Arming and hard disarm


Capturing fields
----------------

Capturing fields is done by specifying a series of WRITE addresses. These are
made up of a mode in the bottom 4 bits, and an index in the 6 bits above them.
Indexes < 32 refer to entries on the pos_bus, while indexes >= 32 are extra
entries specific to PCAP, like timestamps and number of gated samples. The
values sent via the WRITE register are written from the TCP server, so will
not be visible to end users.

Data is ticked out one at a time from the DATA attribute, then sent to the TCP
server over DMA, before being sent to the user. It is reconstructed into a
table in each of the examples below for ease of reading.

The following example shows PCAP being configured to capture the timestamp
when CAPTURE goes high (0x24 is the bottom 32-bits of TS_CAPTURE).

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture timestamp


Pos bus capture
---------------

As well as general fields like the timestamp, any pos_bus index can be captured.
Pos bus fields have multiple modes that they can capture in.


Mode 0 - Value
~~~~~~~~~~~~~~

This gives an instantaneous capture of value no matter what the state of GATE:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 5 Value

Mode 1 - Difference
~~~~~~~~~~~~~~~~~~~

This is mainly used for something like an incrementing counter value.
It will only count the differences while GATE was high:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 11 Difference

Mode 2/3 - Sum Lo/Hi
~~~~~~~~~~~~~~~~~~~~

Mode 2 is the lower 32-bits of the sum of all samples while GATE was high:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 3 Sum

Mode 2 and 3 together gives the full 64-bits of sum, needed for any sizeable
values on the pos_bus:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 2 Sum large values

If long frame times (> 2**32 SAMPLES, > 30s), are to be used, then SHIFT_SUM
can be used to shift both the sum and SAMPLES field by up to 8-bits to
accomodate up to 125 hour frames. This example demonstrates the effect with
smaller numbers:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 9 Sum shifted


Mode 4/5 - Min/Max
~~~~~~~~~~~~~~~~~~

Both of these modes calculate statistics on the value while GATE is high.

Mode 4 produces the min of all values or zero if the gate was low for all of the
current capture:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 8 Min

Mode 5 produces the max of all values in a similar way:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture pos bus entry 4 Max


Number of samples
-----------------

There is a SAMPLES field that can be captured that will give the number of clock
ticks that GATE was high during a single CAPTURE. This field allows the TCP
server to offer "Mean" as a capture option, dividing "Sum" by SAMPLES to get
the mean value of the field during the capture period. It can also be captured
separately to give the gate length:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture gate length


Timestamps
----------

As well as the timestamp of the capture signal, timestamps can also be generated
for the start of each capture period (first gate high signal) and end (the tick
after the last gate high). These are again split into two 32-bit segments so
only the lower bits need to be captured for short captures. In the following
example we capture TS_START (0x20), TS_END (0x22) and TS_CAPTURE (0x24) lower
bits:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture more timestamps


Bit bus capture
---------------

The state of the bit bus at capture can also be captured. It is split into 4
quadrants of 32-bits each. For example, to capture signals 0..31 on the bit bus
we would use BITS0 (0x27):

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture bit bus quadrant 0

By capturing all 4 quadrants (0x27..0x2A) we get the whole bit bus:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture bit bus all quadrants


Triggering options
------------------

ENABLE and GATE are level triggered, with ENABLE used for marking the start and
end of the entire acquisition, and GATE used to accept or reject samples within
a single capture from the acquisition. CAPTURE is edge triggered with an option
to trigger on rising, falling or both edges.

Triggering on rising is the default, explored in the preceding examples.
Triggering on falling edge would be used if you have a gate signal that
marks the capture boundaries and want sum or difference data within. For
example, to capture the amount POS[1] changes in each capture gate we could
connect GATE and CAPTURE to the same signal:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Gate and capture signals the same

Another option would be a gap-less acquisition of sum while gate is high
with capture boundaries marked with a toggle of CAPTURE:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Gap-less sum


Error conditions
----------------

The distance between capture signals must be at least the number of 32-bit
capture fields. If 2 capture signals are too close together HEALTH will be
set to 1 (Capture events too close together).

In this example there are 3 fields captured (TS_CAPTURE_L, TS_CAPTURE_H,
SAMPLES), but only 2 clock ticks between the 2nd and 3rd capture signals:

.. timing_plot::
   :path: targets/PandABox/blocks/pcap/pcap.timing.ini
   :section: Capture too close together
