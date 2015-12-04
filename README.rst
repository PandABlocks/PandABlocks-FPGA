Zebra2 Server
=============

The Zebra2 socket server provides a bridge between the register interface to the
FPGA firmware controlling the Zebra2 hardware and users and other software.  The
interface provided by this server is designed to be simple and robust.

The Zebra2 firmware is structured into numerous functional blocks, with each
block configured via a number of fields.  This structure is directly reflected
in the functional interface provided by this server: most commands read or write
specific fields.

The socket server publishes two socket end points, one for configuration control
the other for streamed data capture.  The configuration control socket accepts
simple ASCII commands and returns all data in readable ASCII format.  The data
capture socket supports no commands and simply streams captured data in a
lightly structured binary format.

Configuration Interface
-----------------------

Configuration commands are sent as newline (ASCII character 0xA0) terminated
strings and all responses are also newline terminated.  Three basic forms of
command are accepted:

Query commands.
    These commands must be terminated by a single ``?`` character.  The three
    possible responses are: an error message, a single value, or a list of
    values.

Assignment commands.
    These commands contain an ``=`` character, and are used for assigning values
    to fields.  The two possible responses are an error message or ``OK``.

Table assignment.
    Any command containing a ``<`` character (not preceded by ``?`` or ``=``) is
    a table assignment command.  The initial command may be followed by any
    number of lines of text, and *must* be terminated by an empty line.  The two
    possible responses are an error message or ``OK``.

The four possible responses are:

``ERR`` error-message
    An error response is always sent as ``ERR`` followed by an error message.

``OK``
    Successful completion of either form of assignment command generates the
    ``OK`` response.

``OK =``\ value
    Successful completion of a query command returning a single value returns
    the value preceded by ``OK =``.

Multi-line response
    Successful completion of a query command returning multiple values returns
    each value on a line by itself starting with ``!`` and ends the sequence
    with a line containing only ``.``.


Example Commands
~~~~~~~~~~~~~~~~

In the examples below, the command sent is shown preceded by ``<`` and the
response with ``>``: this is the syntax used by the helper tool
``simulation/tcp_client.py``:

Simple server identification command::

    < *IDN?
    > OK =PandA

Interrogate list of fields provided by the ``TTLIN`` block::

    < TTLIN.*?
    > !VAL 0 bit_out
    > !TERM 1 param enum
    > .

Interrogate input termination for ``TTLIN1``::

    < TTLIN1.TERM?
    > OK =High-Z

Set input termination::

    < TTLIN1.TERM=50-Ohm
    > OK



Streaming Capture Interface
---------------------------

This has not yet been written.

This interface will stream data configured for capture.
