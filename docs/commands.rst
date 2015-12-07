Command Interface
=================

The default server port for the command interface is port 8888.  All commands
and responses are in ASCII with lines separated with newline characters (ASCII
character 0x0A).

All commands can be grouped into three forms (query, assignment, table
assignment) and two targets (system and fields).  There exactly four possible
response formats (ok, ok with value, error, multiple value).  This section
describes this command interface.

The three basic command forms are:

=========== ======================= ============================================
Name        Format                  Description
=========== ======================= ============================================
Query       target\ ``?``           Interrogates `target` for current value, can
                                    return error, single value or a list of
                                    multiple values.
Assignment  target\ ``=``\ value    Updates `target` with given value, can
                                    return error or success.
Table       target\ ``<``\ format   Command may be followed by lines of text,
                                    *must* be terminated by blank line.
=========== ======================= ============================================

The four basic command responses are:

=========== ======================= ============================================
Name        Format                  Description
=========== ======================= ============================================
Success     ``OK``                  Returned assignment and table commands to
                                    report successful update.
Value       ``OK =``\ value         Successful return of single value from
                                    query command.
Error       ``ERR`` error           Error string returned on any command failure
Multi value | ``!`` value           Any number of values can be returned, each
            | ``.``                 preceded by ``!``, and finally ``.`` by
                                    itself indicates end of input.
=========== ======================= ============================================

Command forms and their possible responses:

=========== ====================================================================
Form        Responses
=========== ====================================================================
Query       Error, Value, Multi value
Assignment  Error, Success
Table       Error, Success
=========== ====================================================================

Each individual query target will either return a single value or multi-value,
as documented below.

Finally, there are two basic types of target: system commands and configuration
commands.

System Command Targets
----------------------

All system commands are prefixed with a leading ``*`` character.  The simplest
command is ``*IDN?`` which returns a system identification string::

    < *IDN?
    > OK =PandA

The available system commands are listed below.

``*IDN?``

    Returns system identification string.  Will probably have system version
    information in the future.

``*ECHO string?``

    Returns string back to caller.  Not terribly useful.  Note that the echoed
    string cannot contain either ``=`` or ``<`` characters, as this would cause
    the command to be mistaken for an assignment or table command!  Example
    usage::

        < *ECHO This is a test?
        > OK =This is a test

``*WHO?``

    Returns list of client connections, for example::

        < *WHO?
        > !2015-12-04T14:30:40.403Z config 127.0.0.1:34185 
        > .

    The first field is the time the connection was made, the second field is
    either ``config`` or ``data`` depending on whether the configuration or data
    port is connected, and the third field is the remote IP address and socket.

``*BLOCKS?``

    Returns a list of all the top level blocks in the system.  The order in
    which the blocks is returned is somewhat arbitrary.  For example (here the
    list has been shortened in the middle)::

        < *BLOCKS?
        > !TTLIN 6
        > !OUTENC 4
        ...
        > !CLOCKS 1
        > !BITS 1
        > !QDEC 4
        > .

    Block and field commands can be used to interrogate each block.  The number
    after each block records the number of instances of each block.

| ``*DESC.``\ block\ ``?``
| ``*DESC.``\ block\ ``.``\ field\ ``?``

    Returns description string for specified block or field, eg::

        < *DESC.TTLIN?
        > OK =TTL input
        < *DESC.TTLIN.TERM?
        > OK =Select TTL input termination

| ``*CHANGES?``
| ``*CHANGES.CONFIG?``
| ``*CHANGES.BITS?``
| ``*CHANGES.POSN?``
| ``*CHANGES.READ?``
| ``*CHANGES.ATTR?``
| ``*CHANGES.TABLE?``

    Reports changes to the appropriate group of values.  Changes are reported
    since the last request on the connection, and on the first request the
    current value for every field will be reported.  The ``*CHANGES?`` command
    reports changes for all groups, otherwise one of the following groups can be
    selected:

    ======= ====================================================================
    CONFIG  Configuration settings
    BITS    Bits on the system bus
    POSN    Positions
    READ    Polled read values
    ATTR    Attributes (included capture enable flags)
    TABLE   Table changes
    ======= ====================================================================

    For example::

        < *CHANGES.CONFIG?
        > !TTLIN1.TERM=High-Z
        > !TTLIN2.TERM=50-Ohm
        > !TTLIN3.TERM=High-Z
        ...
        > !QDEC2.B=TTLIN1.VAL
        > !QDEC3.B=TTLIN1.VAL
        > !QDEC4.B=TTLIN1.VAL
        > .

    Here 804 (at the time of writing) lines have been deleted from the
    transcript!  Now if we repeat the call we see that no further changes have
    happened until something is actually changed::

        < *CHANGES.CONFIG?
        > .
        < TTLOUT4.VAL=TTLIN3.VAL
        > OK
        < *CHANGES.CONFIG?
        > !TTLOUT4.VAL=TTLIN3.VAL
        > .

    Note that for tables only the fact that the table has changed is shown, no
    attempt is made to show the current table value::

        < *CHANGES.TABLE?
        > !PCOMP1.TABLE<
        > !PCOMP2.TABLE<
        > !PCOMP3.TABLE<
        > !PCOMP4.TABLE<
        > !PGEN1.TABLE<
        > !PGEN2.TABLE<
        > !SEQ1.TABLE<
        > !SEQ2.TABLE<
        > !SEQ3.TABLE<
        > !SEQ4.TABLE<
        > .

| ``*CHANGES=``
| ``*CHANGES.CONFIG=``
| ``*CHANGES.BITS=``
| ``*CHANGES.POSN=``
| ``*CHANGES.READ=``
| ``*CHANGES.ATTR=``
| ``*CHANGES.TABLE=``

    These commands reset the change information for the corresponding group of
    information so that only changes occuring after the reset are reported.  For
    example::

        < TTLIN1.TERM=50-Ohm
        > OK
        < *CHANGES=
        > OK
        < *CHANGES.CONFIG?
        > .

``*CAPTURE?``
``*CAPTURE=``
``*BITS``\ n\ ``?``
``*POSITIONS?``

``*VERBOSE=``\ value

    If ``*VERBOSE=1`` is set then every command will be echoed to the server's
    log.  Set ``*VERBOSE=0`` to restore normal quiet behaviour.
