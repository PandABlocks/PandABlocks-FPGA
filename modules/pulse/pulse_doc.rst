PULSE - One-shot pulse delay and stretch
========================================

A PULSE block produces configurable width output pulses with an optional delay
based on its parameters. It operates in one of two modes:

- If WIDTH=0, then it acts as a delay line. The input pulse train will just be
  replayed after the given DELAY
- If WIDTH is non-zero, then each pulse edge that matches TRIG_EDGE will be
  delayed by the specified DELAY, then generate NPULSES pulses of width WIDTH,
  with rising edges separated by STEP

Fields
------

.. block_fields:: modules/pulse/pulse.block.ini

Delay line
----------

If WIDTH=0, then the Block acts as a delay line. DELAY must either be 0 or
5+ clock ticks. TRIG_EDGE, STEP, and NPULSES are ignored.

If DELAY=0 the Block is a simple pass through:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: No delay or stretch

If DELAY is non-zero, rising and falling edges will be inserted in the queue and
output after the given DELAY:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse delay with no stretch

0 < DELAY < 5 will be treated as DELAY=5:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: No WIDTH means a delay of 5 or more is required

Pulse train generation
----------------------

If WIDTH != 0 then the Block will operate in pulse train mode. If NPULSES is
0 or 1 then it will produce a single pulse for each matching input pulse:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse delay and stretch

The output pulses are queued, so multiple pulses can be queued before output:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse train stretched and delayed

The TRIG_EDGE field can be used to select whether an input pulse queues an
output on rising, falling, or both edges:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse stretching with no delay activate on rising edge

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse stretching with no delay activate on falling edge

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Pulse stretching with no delay activate on both edges

0 < WIDTH < 5 will be treated as WIDTH=5:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: No delay means a WIDTH of 5 or more is required

If PULSES > 1 then multiple output pulses will be generated, separated by STEP:
.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Multiple pulses with no delay

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Small delay width combination

Pulse period error
------------------

The following example shows what happens when the period between pulses is too
short. To avoid running output pulses together, the DROPPED field is incremented
and the input is dropped:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Stretched and delayed pulses too close together

The DROPPED count is zeroed on rising edge of ENABLE.

Enabling the Block
------------------

There is an Enable signal that stops the Block from producing signals. Edges
must occur while Enable is high to trigger a pulse creation

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: No pulses if disabled

If enable is dropped mid way through a pulse train, the output is set low and
the QUEUED output is set to zero.

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Multiple pulses interrupted

Changing parameters while Enabled
---------------------------------

If any of the input parameters are changed while enabled, the queue is dropped
and the state of the Block is reset:

.. timing_plot::
   :path: modules/pulse/pulse.timing.ini
   :section: Changing parameters resets pulses
