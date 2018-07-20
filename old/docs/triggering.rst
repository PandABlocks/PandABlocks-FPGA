Triggering schemes
==================

There are a number of ways that the PandA can be used with a live/dead frame
signal to trigger a detector and PCAP.

Fixed exposure gate and trigger
-------------------------------

.. image:: fixed_exposure_gate_trigger.png

(Edit the diagram with `draw.io <https://www.draw.io/?mode=device>`_,
opening the png file from the docs directory).

In this scheme triggers are expected to be a fixed distance apart. The live and
dead signals are used in an SRGate to give a gapless gate signal while the
detector is active. The LUT relies on the extra clock ticks it takes for the
signal to get through the SRGate so that capture signals are generated at
the end of every live frame. A number of detectors can be triggered from Pulse
blocks with delay of readout/2 and width of exposure.

.. sequence_plot::
   :block: system
   :title: Fixed exposure gate and trigger
