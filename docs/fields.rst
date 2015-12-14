Blocks, Fields and Attributes
=============================

The set of hardware blocks can be interrogated with the ``*BLOCKS?`` command::

    < *BLOCKS?
    > !TTLIN 6
    > !OUTENC 4
    > !PCAP 1
    > !PCOMP 4
    > !TTLOUT 10
    > !ADC 8
    > !DIV 4
    > !INENC 4
    > !PGEN 2
    > !LVDSIN 2
    > !POSITIONS 1
    > !POSENC 4
    > !SEQ 4
    > !PULSE 4
    > !SRGATE 4
    > !LUT 8
    > !CALC 2
    > !LVDSOUT 2
    > !COUNTER 8
    > !ADDER 1
    > !CLOCKS 1
    > !BITS 1
    > !QDEC 4
    > .

For each block the number after the block tells us how many instances there are
of the block.  Each block is controlled and interrogated through a number of
fields, and the `block`\ ``.*?`` command can be used to interrogate the list of
fields::

    < TTLIN.*?
    > !VAL 0 bit_out
    > !TERM 1 param enum
    > .

This tells us that block ``TTLIN`` has two fields, ``TTLIN.VAL`` and
``TTLIN.TERM``.  The first field after the field name is a sequence number for
user interface display, and the rest of each response describes the "type" of
the field.  In this case we see that ``TTLIN.VAL`` is a ``bit_out`` field, which
means can be used for bit data capture and can be connected to any ``param
bit_mux`` field as a data source.

Each field has one or more attributes depending on the field type.  The list of
attributes can be interrogated with the `block`\ ``.``\ field\ ``.*?`` command::

    < TTLIN.VAL.*?
    > !CAPTURE_INDEX
    > !CAPTURE
    > !INFO
    > .
    < TTLIN.TERM.*?
    > !LABELS
    > !INFO
    > !RAW
    > .

All fields have the ``.INFO`` attribute, which just repeats the type information
already reported, eg ``TTLIN1.VAL.INFO?`` returns ``bit_out`` (note that a block
number must be specified when interrogating fields and attributes).


Field Types
-----------

Each field type determines the set of attributes available for the field.  The
types and their attributes are documented below.

=================== ============================================================
Field type          Description
=================== ============================================================
``param`` subtype   Configurable parameter.  The `subtype` determines the
                    precise behaviour and the available attributes.
``read`` subtype    A read only hardware field, used for monitoring status.
                    Again, `subtype` determines available attributes.
``write`` subtype   A write only field, `subtype` determines possible values
                    and attributes.
``time``            Configurable timer parameter.
``bit_out``         Bit output, can be configured for data capture and as bit
                    input for ``param bit_mux`` fields.
``pos_out``         Position output, can be configured for data capture and as
                    position input for ``param pos_mux`` fields.
``table``           Table data with special access methods.
=================== ============================================================

``param`` subtype
    All fields of this type contribute to the ``*CHANGES.PARAM`` change group
    and are used to configure the behaviour of the corresponding block.  Fields
    of this type are used for input configuration and other behavioural
    settings.

``read`` subtype
    All fields of this type contribute to the ``*CHANGES.READ`` change group,
    but are only checked when either the field is read or the change group is
    polled.  Fields of this type are used for monitoring the internal status of
    a block, and they cannot be written to.

``write`` subtype
    Fields of this type can only be written and are used for immediate actions
    on a block.  The ``action`` subtype is used to support actions without any
    parameters, for example the followig command forces a soft reset on the
    given pulse block::

        < PULSE1.FORCE_RESET=
        > OK

``time``
    Fields of this type are used for configuring delays.  They also contribute
    to ``*CHANGES.PARAM``.  The following attributes are supported by fields of
    this type:

    ``UNITS``
        This attribute can be set to any of the strings ``min``, ``s``, ``ms``,
        or ``us``, and is used to interpret how values read and written to the
        field are interpreted.

    ``RAW``
        This attribute can be read or written to report or set the delay in FPGA
        ticks.

    The ``UNITS`` attribute determines how numbers read or written to the field
    are interpreted.  For example::

        < PULSE1.DELAY.UNITS=s
        > OK
        < PULSE1.DELAY=2.5
        > OK
        < PULSE1.DELAY.RAW?
        > OK =312500000
        < PULSE1.DELAY.UNITS=ms
        > OK
        < PULSE1.DELAY?
        > OK =2500

    Note that changing ``UNITS`` doesn't change the delay, only how it is
    reported and interpreted.

``bit_out``
    Fields of this type are used for block outputs which contribute to the
    internal bit system bus, and they contribute to the ``*CHANGES.BITS`` change
    group.  The following attributes are supported by fields of this type:

    ``CAPTURE``
        This read/write field can be set to 1 to enable capture of this bit.
        Enabling capture will enable the corresponding ``*BITS``\ n block as
        reported by ``*CAPTURE?``.

    ``CAPTURE_INDEX``
        This reports exactly where this bit will be captured, for example::

            < TTLIN3.VAL.CAPTURE_INDEX?
            > OK =3:2
            < *CAPTURE?
            > !INENC1.ENC_POSN
            > !INENC2.ENC_POSN
            > !INENC3.ENC_POSN
            > !*BITS0
            > .

        The capture index ``3:2`` tells us that this bit will be captured as bit
        number 2 of the capture word number 3, ``*BITS0`` as reported by
        ``*CAPTURE?``.

        If the field is not enabled for capture then this field returns an empty
        string.

    The field itself can be read to return the current value of the bit.

``pos_out``
    Fields of this type are used for block outputs which contribute to the
    internal position bus, and they contribute to the ``*CHANGES.POSN`` change
    group.  The following attributes support capture control:

    ``CAPTURE``
        As for ``bit_out``, this field is used to enable capture of this
        position output.

    ``CAPTURE_INDEX``
        This is the sequence number of the captured word as reported by
        ``*CAPTURE?`` or blank.

    The following attributes support formatting of the field when reading it:
    the current value is returned subject to the formatting rules described
    below.

    ``OFFSET``, ``SCALE``
        These numbers can be set to configure the conversion from the underlying
        position to the reported value.  The value reported when reading the
        field is

            raw * scale + offset

    ``UNITS``
        This field can be set to any string, and is provided for the convenience
        of the user interface.

    ``RAW``
        This returns the underlying 32-bit number on the position bus.

``table``
    Values of this type are used for long tables of numbers.  This server
    imposes no structure on these values apart from treating them as an array of
    32-bit integers.

    Tables values are written with the special ``<`` syntax:

    =================================== ========================================
    block number\ ``.``\ field\ ``<``   Normal table write, overwrite table
    block number\ ``.``\ field\ ``<<``  Normal table write, append to table
    block number\ ``.``\ field\ ``<B``  Base-64 table write, overwrite table
    block number\ ``.``\ field\ ``<<B`` Base-64 table write, append to table
    =================================== ========================================

    For "normal" table writes the data is sent as a sequence of decimal numbers
    in ASCII, and the whole sequence must be terminate by an empty blank line.
    For base-64 writes the data is sent in base-64 format, for example::

        < SEQ3.TABLE<B
        < TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1
        <
        > OK
        < SEQ3.TABLE.LENGTH?
        > OK =12

    The following attributes are provided by this field type:

    ``MAX_LENGTH``
        This is the maximum number of 32-bit words which can be stored in the
        table.

    ``LENGTH``
        This is the current number of words in the table.  The rest of the table
        is filled with zeros.

    ``B``
        This read-only attribute returns the content of the table in base-64.

    ``FIELDS``
        This returns a list of strings which can be used to interpret the
        content of the table.  Currently the content of this list is not
        defined.


Field Sub-Types
---------------

The following field sub-types can be used for ``param``, ``read`` and ``write``
fields.

``uint``
    This is the most basic type: the value read or written is a 32-bit number.
    There is one fixed attribute:

    ``MAX``
        This returns the maximum value that can be written to this field.

``bit``
    A value which is 0 or 1, there are no extra attributes.

``action``
    A value which cannot be read and always writes as 0.  Only useful for
    ``write`` fields.

``bit_mux``, ``pos_mux``
    Input selectors for blocks.  Each of these fields can be set to the name of
    a corresponding ``bit_out`` or ``pos_out`` field, for example::

        < TTLOUT1.VAL=TTLIN1.VAL
        > OK

    There are no extra attributes.

``lut``
    This field sub-type is used for the 5-input lookup table function
    calculation field.  This field can be set to any valid logical expression
    generated from inputs ``A`` to ``E`` using the standard operators ``&``,
    ``|``, ``^``, ``~``, ``?:`` from C together with ``=`` for equality and
    ``=>`` for implication (``A=>B`` abbreviates ``~A|B``).  All operations have
    C precedence, ``=`` has the same precedence as ``==`` in C, and ``=>`` has
    precedence between ``|`` and ``?:``.

    The following attribute is supported:

    ``RAW``
        This returns the corresponding lookup table assignment as a 32-bit
        number.

    For example::

        < LUT2.FUNC=A=>B?C:D
        > OK
        < LUT2.FUNC?
        > OK =A=>B?C:D
        < LUT2.FUNC.RAW?
        > OK =4039962864


``enum``
    Enumeration fields define a list of valid strings which can be written to
    the field.  One attributes is supported:

    ``LABELS``
        This returns the list of valid enumeration values, for example::

            < TTLIN1.TERM.LABELS?
            > !High-Z
            > !50-Ohm
            > .


Summary of Sub-Types
--------------------

=========== =========== ========================================================
Sub-type    Attributes  Description
=========== =========== ========================================================
uint        MAX         Possibly bounded 32-bit unsigned integer value
bit                     Bit: 0 or 1
action                  Write only, no value
bit_mux                 Bit input multiplexer selection
pos_mux                 Position input mutiplexer selection
lut         RAW         5 input lookup table logical formula
enum        LABELS      Enumeration selection
=========== =========== ========================================================


Summary of Attributes
---------------------

=============== =============== ======================================= = = = =
Field (sub)type Attribute       Description                             R W C M
=============== =============== ======================================= = = = =
(all)           INFO            Returns type of field                   R
uint            MAX             Maximum allowed integer value           R
lut             RAW             Computed Lookup Table 32-bit value      R
enum            LABELS          List of enumeration labels              R     M
time            UNITS           Units and scaling selection for time    R W C
\               RAW             Raw time in FPGA clock cycles           R W
bit_out         CAPTURE         Bit capture control                     R W C
\               CAPTURE_INDEX   Bit capture word and bit index          R
pos_out         CAPTURE         Position capture control                R W C
\               CAPTURE_INDEX   Position capture word index             R
\               OFFSET          Position offset                         R W C
\               SCALE           Position scaling                        R W C
\               UNITS           Position units                          R W C
\               RAW             Underlying raw position value           R
table           MAX_LENGTH      Maximum table row count                 R
\               LENGTH          Current table row count                 R
\               B               Table data in base-64                   R     M
\               FIELDS          Table field descriptions                R     M
=============== =============== ======================================= = = = =

Key:
    :R:     Attribute can be read
    :W:     Attribute can be written
    :C:     Attribute contributes to ``*CHANGES.ATTR`` change set
    :M:     Attribute returns multiple value result.
