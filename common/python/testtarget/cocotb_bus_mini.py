# A minimal cocotb bus and monitor implementation for avoiding extra
# dependency, as we only use a couple of classes from cocotb-bus.

import cocotb


class Bus(object):
    def __init__(self, dut, name, signals):
        self.dut = dut
        self.name = name
        self._signals = {}
        for sig in signals:
            handle = dut[f'{name}_{sig}'] if name else dut[sig]
            self._signals[sig] = handle
            setattr(self, sig, handle)


class Monitor(object):
    def __init__(self, callback=None):
        self._callbacks = []
        if callback:
            self.add_callback(callback)

        # Create an independent coroutine which can receive stuff
        self._thread = cocotb.start_soon(self._monitor_recv())

    def add_callback(self, callback):
        self._callbacks.append(callback)

    def _monitor_recv(self):
        """Actual implementation of the receiver.

        Sub-classes should override this method to implement the actual receive
        routine and call :meth:`_recv` with the recovered transaction.
        """
        raise NotImplementedError(
            "Attempt to use base monitor class without "
            "providing a ``_monitor_recv`` method"
        )

    def _recv(self, transaction):
        """Common handling of a received transaction."""

        for callback in self._callbacks:
            callback(transaction)


class BusMonitor(Monitor):
    _signals = []

    def __init__(self, dut, name, clock, callback=None, **kwargs):
        self.bus = Bus(dut, name, self._signals, **kwargs)
        self.clock = clock
        Monitor.__init__(self, callback)
