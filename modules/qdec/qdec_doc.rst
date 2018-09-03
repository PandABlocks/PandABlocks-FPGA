QDEC - Quadrature Decoder
=========================
The QDEC block handles the encoder Decoding

Fields
------

.. block_fields:: modules/qdec/qdec.block.ini


Tests
-----

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Up then Down

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Up then down with reset and change of Set Point

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: No Set Point

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Variable quadrature period

.. timing_plot::
	:path: modules/qdec/qdec.timing.ini
	:section: Faster input than output