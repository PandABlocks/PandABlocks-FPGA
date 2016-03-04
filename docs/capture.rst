Data Capture
============

Capture Configuration
---------------------

Both ``pos_out`` and ``ext_out`` fields can be configured for data capture
through the data capture port by setting the appropriate value in the
``CAPTURE`` attribute.  The possible capture settings depend on the field type
as follows:

``pos_out``
    =========== ============================================================== =
    No          Capture disabled
    Triggered   Capture value at trigger point
    Difference  Capture difference within captured frame                       F
    =========== ============================================================== =

``pos_out encoder``
    =========== ============================================================== =
    No          Capture disabled
    Triggered   Capture value at trigger point
    Difference  Capture difference within captured frame                       F
    Average     Average of values at either end of captured frame              F
    Extended    Capture full 48-bit encoder value at trigger point
    =========== ============================================================== =

``pos_out adc``
    =========== ============================================================== =
    No          Capture disabled
    Triggered   Capture value at trigger point
    Average     Average ADC samples within captured frame                      F
    =========== ============================================================== =

``ext_out`` (except ``ext_out timestamp``)
    =========== ============================================================== =
    No          Capture disabled
    Capture     Capture value at trigger point
    =========== ============================================================== =

``ext_out timestamp``
    =========== ============================================================== =
    No          Capture disabled
    Trigger     Capture timestamp at trigger point
    Frame       Capture timestamp at start of frame                            F
    =========== ============================================================== =

Key:
    :F: Framing mode is enabled


Data Capture Port
-----------------
