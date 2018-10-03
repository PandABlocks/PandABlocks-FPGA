QDEC - Quadrature Decoder
=========================
The QDEC block handles the encoder Decoding

Fields
------

.. block_fields:: modules/qdec/qdec.block.ini


Counting
--------

The quadrature decoder counts, incrementing at each rising or falling edge of
the sequence. If the sequence is reversed the count will decrease at each edge.
The initial value is set to the value of the SETP input.

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: No Set Point

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Up then Down

Resetting
---------

Whilst counting, it can be reset to '0' on while the Z input is high, provided
that this functionality is enabled by setting the RST_ON_Z input to '1'. If the
SETP input is changed the count value changes to the new value.

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Up then down with reset and change of Set Point

Limitations
-----------

The block can continue to count when there is not a constant period between the
pulses.

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Variable quadrature period

The output takes three clock pulses to update. If the inputs are changing faster
than this, inputs can be lost.

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Faster input than output