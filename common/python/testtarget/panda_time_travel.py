"""Time travel for the testtarget simulation.

The simulator runs orders of magnitude slower than the 125 MHz FPGA clock, so
a CLOCK block with a one second period would take hours of wall-clock time to
toggle. ``PandaTimeTravel`` keeps a Python model of every tick-counting entity
in the design and makes the simulated tick count chase the wall clock. Each
clock edge it works out the *lag*, the number of ticks the wall clock says are
due that have not been simulated yet, and moves *all* the models forward
together by that many ticks (a "jump"), never past the earliest pending event
(a change that other blocks may observe). A jump that lands on an event is
followed by real clock cycles so that the event and its effects propagate
through the design before the next jump; a jump short of every event changes
nothing observable and needs none. Between events the server blocks until the
wall clock reaches the earliest one (``compute_timeout``), so a command that
interrupts the wait is applied only once the models have been moved to the
tick that is due then.

Jumping every entity by the same amount in the same clock cycle is what keeps
them consistent with each other: the timestamp counter of a PULSE block sees
exactly the same elapsed time as the CLOCK block that triggers it, and PCAP
timestamps and sample counts match both.

Models read the design state right after a rising clock edge, before the
processes triggered by that edge have updated their signals, and deposit the
advanced values so they replace the single-tick update the processes are
about to make. The edge is therefore absorbed into the jump: everything moves
by exactly ``n`` ticks, not ``n + 1``.
"""
import logging
import time

import cocotb
from cocotb.handle import HierarchyArrayObject, HierarchyObject
from cocotb.triggers import ClockCycles, RisingEdge

DEFAULT_TIMEOUT = 60  # seconds


def _unsigned(sig):
    return sig.value.to_unsigned()


def _signed(sig):
    return sig.value.to_signed()


def _mask(sig):
    return (1 << len(sig)) - 1


class TickModel:
    """Python model of one tick-counting entity in the design.

    ``remaining()`` returns the number of clock ticks until the entity's next
    event (a change that other blocks may observe), or ``None`` when it has no
    pending event. ``advance(n)`` moves the entity's state forward by ``n``
    ticks; the coordinator guarantees ``n <= remaining()`` for models that
    reported a pending event, so no event is ever skipped.
    """

    def __init__(self, inst):
        self.inst = inst
        self.path = inst._path

    def remaining(self):
        return None

    def advance(self, n):
        raise NotImplementedError


class PrescaledTimerModel(TickModel):
    """``prescaled_timer``: ``precounter`` counts 0..P, ``counter`` 0..T.

    Events are the timer expiring, when both have reached their rollover
    values, and the output going low when ``counter = low`` with the
    prescaler rolled (only if ``low`` is within the counter's range: a block
    that leaves the output unused ties ``low`` to all ones).
    """

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_i = inst.enable_i
        self.prescaler_rollover_i = inst.prescaler_rollover_i
        self.timer_rollover_i = inst.timer_rollover_i
        self.low_i = inst.low_i
        self.counter = inst.counter
        self.precounter = inst.precounter

    def remaining(self):
        if self.enable_i.value != 1:
            return None
        prescale = _unsigned(self.prescaler_rollover_i)
        rollover = _unsigned(self.timer_rollover_i)
        counter = _unsigned(self.counter)
        precounter = _unsigned(self.precounter)
        if counter > rollover or precounter > prescale:
            # Parameters changed under the running timer: let the RTL sort
            # itself out with real clock cycles.
            return 0
        total = counter * (prescale + 1) + precounter
        end = rollover * (prescale + 1) + prescale
        pending = [end - total]
        low = _unsigned(self.low_i)
        if low <= rollover:
            low_end = low * (prescale + 1) + prescale
            if low_end >= total:
                pending.append(low_end - total)
        return min(pending)

    def advance(self, n):
        if self.enable_i.value != 1:
            return
        prescale = _unsigned(self.prescaler_rollover_i)
        total = _unsigned(self.counter) * (prescale + 1) + \
            _unsigned(self.precounter) + n
        self.counter.value = total // (prescale + 1)
        self.precounter.value = total % (prescale + 1)


class PulseTrainModel(TickModel):
    """``pulse_train``: ``pulse_counter`` counts down to the next output edge
    while ``edges_remaining`` is non-zero."""

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_i = inst.enable_i
        self.edges_remaining = inst.edges_remaining
        self.pulse_counter = inst.pulse_counter

    def _active(self):
        return self.enable_i.value == 1 and \
            _unsigned(self.edges_remaining) != 0

    def remaining(self):
        if not self._active():
            return None
        return _unsigned(self.pulse_counter)

    def advance(self, n):
        if not self._active():
            return
        self.pulse_counter.value = _unsigned(self.pulse_counter) - n


class TimestampQueueModel(TickModel):
    """``timestamp_queue``: free-running ``timestamp`` compared against the
    absolute timestamps queued in its FIFO.

    The counter must advance whenever the block is enabled, even with nothing
    queued, because later triggers are stamped relative to it.
    """

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_i = inst.enable_i
        self.read_valid = inst.read_valid
        self.timestamp = inst.timestamp
        self.timestamp_mask = _mask(self.timestamp)
        self.queue_pulse_ts = inst.queue_pulse_ts
        self.pulse_override_o = inst.pulse_override_o
        self.override_ends_ts = inst.override_ends_ts

    def remaining(self):
        if self.enable_i.value != 1:
            return None
        timestamp = _unsigned(self.timestamp)
        pending = []
        # The RTL compares a wrapping counter for equality, so a target below
        # the current timestamp is due once the counter has wrapped round to
        # it: the distance to every target is taken modulo the counter width.
        if self.read_valid.value == 1:
            pending.append(
                (_unsigned(self.queue_pulse_ts) - timestamp) &
                    self.timestamp_mask)
        if self.pulse_override_o.value == 1:
            pending.append(
                (_unsigned(self.override_ends_ts) - timestamp) &
                    self.timestamp_mask)
        if not pending:
            return None
        return min(pending)

    def advance(self, n):
        if self.enable_i.value != 1:
            return
        self.timestamp.value = \
            (_unsigned(self.timestamp) + n) & self.timestamp_mask


class PcapTimestampModel(TickModel):
    """``pcap_arming``: timestamp counting from ARM while enabled."""

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_i = inst.enable_i
        self.pcap_armed = inst.pcap_armed
        self.timestamp = inst.timestamp

    def advance(self, n):
        if self.pcap_armed.value != 1 or self.enable_i.value != 1:
            return
        timestamp = _unsigned(self.timestamp)
        if timestamp > 0:
            self.timestamp.value = (timestamp + n) & _mask(self.timestamp)


class PcapFrameModel(TickModel):
    """``pcap_frame``: counts gated samples between captures (SAMPLES)."""

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_i = inst.enable_i
        self.gate_i = inst.gate_i
        self.cnt_samples = inst.cnt_samples

    def advance(self, n):
        if self.enable_i.value != 1 or self.gate_i.value != 1:
            return
        self.cnt_samples.value = \
            (_unsigned(self.cnt_samples) + n) & _mask(self.cnt_samples)


class PcapFrameModeModel(TickModel):
    """``pcap_frame_mode``: running sum and sum of squares of the gated value.

    Min, max and difference do not depend on the number of ticks, so only the
    accumulators need advancing. The value is constant during a jump.
    """

    def __init__(self, inst):
        super().__init__(inst)
        self.enable_r1 = inst.enable_r1
        self.gate_r1 = inst.gate_r1
        self.value_r1 = inst.value_r1
        self.sum_data = inst.sum_data
        self.sum_data_mask = _mask(self.sum_data)
        self.sum_data_sq = inst.sum_data_sq
        self.sum_data_sq_mask = _mask(self.sum_data_sq)

    def advance(self, n):
        if self.enable_r1.value != 1 or self.gate_r1.value != 1:
            return
        value = _signed(self.value_r1)
        self.sum_data.value = \
            (_signed(self.sum_data) + n * value) & self.sum_data_mask
        self.sum_data_sq.value = \
            (_unsigned(self.sum_data_sq) + n * value * value) & \
                self.sum_data_sq_mask


class FilterModel(TickModel):
    """``filter`` in average mode: accumulates the input and a sample count
    on every tick while enabled."""

    AVERAGE = 1

    def __init__(self, inst):
        super().__init__(inst)
        self.mode = inst.mode
        self.enable_i_dly = inst.enable_i_dly
        self.inp_i = inst.inp_i
        self.sum_i = inst.sum_i
        self.sum_i_mask = _mask(self.sum_i)
        self.sum_num = inst.sum_num
        self.sum_num_mask = _mask(self.sum_num)

    def advance(self, n):
        if self.enable_i_dly.value != 1:
            return
        mode = self.mode.value
        # the MODE register port stays 'U' until the register is written for
        # the first time; the server does that at startup, tests may not
        if not mode.is_resolvable or (mode.to_unsigned() & 1) != self.AVERAGE:
            return
        self.sum_i.value = \
            (_signed(self.sum_i) + n * _signed(self.inp_i)) & self.sum_i_mask
        self.sum_num.value = (_unsigned(self.sum_num) + n) & self.sum_num_mask


MODEL_CLASSES = {
    'prescaled_timer': PrescaledTimerModel,
    'pulse_train': PulseTrainModel,
    'timestamp_queue': TimestampQueueModel,
    'pcap_arming': PcapTimestampModel,
    'pcap_frame': PcapFrameModel,
    'pcap_frame_mode': PcapFrameModeModel,
    'filter': FilterModel,
}


class PandaTimeTravel:
    # we jump only if the jump is bigger than this value
    JUMP_THRES = 512
    # after an event or a command, force this many real clock cycles before
    # another jump is allowed so that the event propagates through the design
    # (bit bus delays, pipelines, FIFOs)
    MIN_TICKS = 38

    def __init__(self, dut, fpga_clock_freq=125000000):
        self.log = logging.getLogger(__class__.__name__)
        self.dut = dut
        self.fpga_clock_freq = fpga_clock_freq
        self.pcap_fifo_count = dut.pcap_inst.pcap_dma_inst.fifo_count
        self.models = []
        self.find_models()
        # simulated ticks elapsed, including the jumped ones
        self.timestamp = 0
        # wall-clock time of simulated tick 0: tick ``t`` is due at
        # ``origin + t / fpga_clock_freq``; moved only by ``jump``
        self.origin = time.time()
        # real clock cycles still to run before the next jump is allowed
        self.post_jump_cycles = 0
        # ticks to the earliest pending event as of the last ``step``, None
        # when nothing is counting down
        self.next_event = None
        # statistics
        self.advanced_ticks = 0
        self.extra_delay = 0
        self.njumps = 0
        cocotb.start_soon(self.run())

    def find_models(self):
        frontier = [self.dut]
        while frontier:
            current = frontier.pop()
            # generate-loop arrays share the definition name of their
            # instances, only the instances themselves have the signals
            model_class = MODEL_CLASSES.get(current._def_name.lower()) \
                if isinstance(current, HierarchyObject) else None
            if model_class is not None:
                self.log.info('Modelling %s as %s',
                              current._path, model_class.__name__)
                self.models.append(model_class(current))

            if isinstance(current, HierarchyObject):
                for name in dir(current):
                    if not name.startswith('_'):
                        frontier.append(getattr(current, name))
            elif isinstance(current, HierarchyArrayObject):
                for i in range(len(current)):
                    frontier.append(current[i])

    def pcap_busy(self):
        # don't jump while PCAP is collecting samples or draining its DMA
        # FIFO - it needs every real clock edge processed
        return self.pcap_fifo_count.value.to_unsigned() != 0

    def delay_wait(self):
        self.post_jump_cycles = self.MIN_TICKS

    def lag(self, now):
        """Ticks due by the wall clock that have not been simulated yet."""
        return int((now - self.origin) * self.fpga_clock_freq) - self.timestamp

    def compute_timeout(self):
        """Seconds the caller may block before the next clock edge matters.

        0 means every edge is needed, otherwise it is the time left until the
        earliest event is due, capped at ``DEFAULT_TIMEOUT`` (which is also
        what an idle scheduler returns) so that the caller wakes up now and
        then.
        """
        if self.post_jump_cycles > 0 or self.pcap_busy() or \
                (self.next_event is not None and
                 self.next_event < self.JUMP_THRES):
            return 0
        if self.next_event is None:
            return DEFAULT_TIMEOUT
        wait = (self.next_event - self.lag(time.time())) / self.fpga_clock_freq
        return min(DEFAULT_TIMEOUT, max(0, wait))

    async def run(self):
        edge = RisingEdge(self.dut.clk_i)
        # wait for the design to be stable
        await ClockCycles(self.dut.clk_i, 2)
        while True:
            await edge
            self.step()

    def step(self):
        if self.post_jump_cycles > 0:
            self.post_jump_cycles -= 1
        pending = [remaining for remaining in
                   (model.remaining() for model in self.models)
                   if remaining is not None]
        self.next_event = min(pending, default=None)
        if self.next_event is not None and self.next_event <= 0:
            # an event fires on this edge: give it real cycles to propagate
            self.delay_wait()

        now = time.time()
        lag = self.lag(now)
        ticks = lag if self.next_event is None else min(lag, self.next_event)
        if self.post_jump_cycles == 0 and not self.pcap_busy() \
                and ticks >= self.JUMP_THRES:
            self.jump(ticks, lag, now)
        else:
            # a plain edge (a jump absorbs its edge)
            self.timestamp += 1

    def jump(self, ticks, lag, now):
        self.log.debug('Jumping %d ticks at timestamp %d', ticks, self.timestamp)
        for model in self.models:
            model.advance(ticks)

        self.timestamp += ticks
        self.advanced_ticks += ticks
        self.njumps += 1
        if ticks == self.next_event:
            # landed on an event: it is late by the lag beyond it, and it
            # needs real cycles to propagate (a jump short of every event
            # changes nothing observable, so it opens no window)
            self.extra_delay += (lag - ticks) / self.fpga_clock_freq
            self.delay_wait()
        # don't accumulate lateness: the next deadline is relative to this jump
        self.origin = now - self.timestamp / self.fpga_clock_freq
