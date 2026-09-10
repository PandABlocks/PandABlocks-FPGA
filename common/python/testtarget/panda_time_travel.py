import logging
import time

from enum import Enum, auto

import cocotb

from cocotb.handle import HierarchyObject, HierarchyArrayObject
from cocotb.triggers import ClockCycles, RisingEdge, ReadOnly

DEFAULT_TIMEOUT = 60  # seconds


class ClockTimerState(Enum):
    IDLE = auto()
    WAIT_FOR_LOW = auto()
    WAIT_FOR_ZERO = auto()


class PrescaledTimerState(Enum):
    IDLE = auto()
    WAIT_FOR_COUNTER = auto()


class PulseTrainState(Enum):
    IDLE = auto()
    WAIT_FOR_COUNTER = auto()


class TimeStampQueueState(Enum):
    IDLE = auto()
    WAIT_FOR_COUNTER = auto()


class PcapFrameModeHelper:
    SUM_MASK = 2**72 - 1
    SQ_MASK = 2**104 - 1

    def __init__(self, inst):
        self.inst = inst
        self.enable_i = inst.enable_i
        self.trig_r1 = inst.trig_r1
        self.gate_r1 = inst.gate_r1
        self.value_r1 = inst.value_r1
        self.sum_data = inst.sum_data
        self.sum_data_sq = inst.sum_data_sq

    def advance(self, diff_ticks):
        if self.enable_i.value != 1 or self.gate_r1.value != 1:
            return

        self.sum_data.value = \
            (self.sum_data.value.to_unsigned() + \
                diff_ticks * self.value_r1.value.to_unsigned()) & self.SUM_MASK

        self.sum_data_sq.value = \
            (self.sum_data_sq.value.to_unsigned() + \
                diff_ticks * self.value_r1.value.to_unsigned() ** 2) & \
                    self.SQ_MASK


class PandaTimeTravel:
    # we jump only if jump is bigger than this value
    JUMP_THRES = 512
    # after a jump, force this many real polling cycles before another jump
    # is allowed, giving the simulation a chance to actually run for a bit
    MIN_TICKS = 38

    def __init__(self, dut, fpga_clock_freq=125000000):
        self.log = logging.getLogger(__class__.__name__)
        self.dut = dut
        self.pcap_fifo_count = dut.pcap_inst.pcap_dma_inst.fifo_count
        self.fpga_clock_freq = fpga_clock_freq
        self.timestamp = 0
        cocotb.start_soon(self.timestamp_inc())
        self.pcap_frame_modes = []
        self.pending_deadlines = {}
        self.busy_keys = set()
        self.post_jump_cycles = 0
        self.watch_entities()
        self.advanced_ticks = 0
        self.was_advanced = False
        self.pcap_timestamp = \
            self.dut.pcap_inst.pcap_core_inst.pcap_arming.timestamp

    def register_deadline(self, key, end_time):
        self.pending_deadlines[key] = end_time

    def clear_deadline(self, key):
        self.pending_deadlines.pop(key, None)

    def next_deadline(self):
        # earliest real wall-clock time at which some timer is due to jump,
        # or None if nothing is currently counting down
        if not self.pending_deadlines:
            return None

        return min(self.pending_deadlines.values())

    def mark_busy(self, key):
        # a timer that's running but below JUMP_THRES never gets a
        # registered deadline - it still needs a real clock edge every
        # cycle to decrement, so blocking would freeze it incorrectly
        self.busy_keys.add(key)

    def clear_busy(self, key):
        self.busy_keys.discard(key)

    def pcap_busy(self):
        # don't jump while PCAP is collecting samples or draining its DMA
        # FIFO - it needs every real clock edge processed
        return self.pcap_fifo_count.value.to_unsigned() != 0

    def boost_timeout(self):
        self.post_jump_cycles = self.MIN_TICKS

    def compute_timeout(self):
        if self.post_jump_cycles > 0:
            self.post_jump_cycles -= 1
            return 0

        if self.busy_keys or self.pcap_busy():
            return 0

        deadline = self.next_deadline()
        if deadline is None:
            return DEFAULT_TIMEOUT

        return max(0, deadline - time.time())

    def advance_timestamp_in_pcap(self, diff_ticks):
        current_pcap_timestamp = self.pcap_timestamp.value.to_unsigned()
        if current_pcap_timestamp > 0:
            self.pcap_timestamp.value = current_pcap_timestamp + diff_ticks
            for pcap_frame_mode in self.pcap_frame_modes:
                pcap_frame_mode.advance(diff_ticks)

    def advance_timestamp(self, target_timestamp):
        diff_ticks = target_timestamp - self.timestamp
        if diff_ticks > 0:
            self.advanced_ticks += diff_ticks
            self.advance_timestamp_in_pcap(diff_ticks)
            self.timestamp = target_timestamp
            self.was_advanced = True
            self.boost_timeout()

    async def timestamp_inc(self):
        while True:
            await RisingEdge(self.dut.clk_i)
            await ReadOnly()
            if not self.was_advanced:
                self.timestamp += 1

            self.was_advanced = False

    def add_pcap_frame_mode(self, pcap_frame_mode_inst):
        self.pcap_frame_modes.append(PcapFrameModeHelper(pcap_frame_mode_inst))

    def watch_entities(self):
        watchers = {
            'timer_for_clock': self.watch_clock_timer,
            'prescaled_timer': self.watch_prescaled_timer,
            'pulse_train': self.watch_pulse_train,
            'timestamp_queue': self.watch_timestamp_queue,
        }
        functions = {
            'pcap_frame_mode': self.add_pcap_frame_mode,
        }
        frontier = [self.dut]
        while frontier:
            current = frontier.pop()
            path = current._path
            entity = current._def_name.lower()
            watch = watchers.get(entity, None)
            if watch is not None:
                print(f'Watching: {path}')
                cocotb.start_soon(watch(current))

            func = functions.get(entity, None)
            if func is not None:
                print(f'Processing: {path}')
                func(current)

            if isinstance(current, HierarchyObject):
                for name in dir(current):
                    if not name.startswith('_'):
                        frontier.append(getattr(current, name))
            elif isinstance(current, HierarchyArrayObject):
                for i in range(len(current)):
                    frontier.append(current[i])

    async def watch_clock_timer(self, timer):
        state = ClockTimerState.IDLE
        end_time = 0
        low = 0
        # wait for the timer to be stable
        await ClockCycles(timer.clk_i, 2)
        while True:
            await RisingEdge(timer.clk_i)
            match state:
                case ClockTimerState.IDLE:
                    if timer.enable_i.value == 0:
                        self.clear_busy(id(timer))
                        continue
                    auto_reload = timer.auto_reload_i.value.to_unsigned()
                    if auto_reload >= self.JUMP_THRES:
                        self.clear_busy(id(timer))
                        state = ClockTimerState.WAIT_FOR_LOW
                        low = timer.low_i.value.to_unsigned()
                        end_time = time.time() + \
                            (auto_reload - low) / self.fpga_clock_freq
                        end_tick = self.timestamp + auto_reload - low
                        self.register_deadline(id(timer), end_time)
                        # make sure we do a few cycles after enabling
                        self.boost_timeout()
                    else:
                        # running, but too short to be worth jumping - it
                        # still needs real clock edges to progress
                        self.mark_busy(id(timer))

                case ClockTimerState.WAIT_FOR_LOW:
                    if timer.enable_i.value == 0:
                        state = ClockTimerState.IDLE
                        self.clear_deadline(id(timer))
                    elif timer.counter.value.to_unsigned() == low:
                        end_time = time.time() + low / self.fpga_clock_freq
                        end_tick = self.timestamp + low
                        state = ClockTimerState.WAIT_FOR_ZERO
                        self.register_deadline(id(timer), end_time)
                    elif time.time() >= end_time and not self.pcap_busy():
                        # see you in the future
                        self.advance_timestamp(end_tick)
                        timer.counter.value = low

                case ClockTimerState.WAIT_FOR_ZERO:
                    if timer.enable_i.value == 0:
                        state = ClockTimerState.IDLE
                        self.clear_deadline(id(timer))
                    elif timer.counter.value == 0:
                        end_time = time.time() + \
                            (auto_reload - low) / self.fpga_clock_freq
                        end_tick = self.timestamp + auto_reload - low
                        state = ClockTimerState.WAIT_FOR_LOW
                        self.register_deadline(id(timer), end_time)
                    elif time.time() >= end_time and not self.pcap_busy():
                        # see you in the future
                        self.advance_timestamp(end_tick)
                        timer.counter.value = 0

    async def watch_prescaled_timer(self, timer):
        state = PrescaledTimerState.IDLE
        # wait for the timer to be stable
        await ClockCycles(timer.clk_i, 2)
        while True:
            await RisingEdge(timer.clk_i)
            match state:
                case PrescaledTimerState.IDLE:
                    if timer.enable_i.value == 1:
                        ticks = \
                            (timer.prescaler_rollover_i.value.to_unsigned() + 1) \
                            * (timer.timer_rollover_i.value.to_unsigned() + 1)
                        if ticks >= self.JUMP_THRES:
                            self.clear_busy(id(timer))
                            end_time = time.time() + ticks / self.fpga_clock_freq
                            end_tick = self.timestamp + ticks
                            state = PrescaledTimerState.WAIT_FOR_COUNTER
                            self.register_deadline(id(timer), end_time)
                            # make sure we do a few cycles after enabling
                            self.boost_timeout()
                        else:
                            self.mark_busy(id(timer))
                    else:
                        self.clear_busy(id(timer))
                case PrescaledTimerState.WAIT_FOR_COUNTER:
                    if timer.enable_i.value == 0:
                        state = PrescaledTimerState.IDLE
                        self.clear_deadline(id(timer))
                    elif time.time() >= end_time and not self.pcap_busy():
                        self.advance_timestamp(end_tick)
                        timer.counter.value = timer.timer_rollover_i.value
                        timer.precounter.value = timer.prescaler_rollover_i.value
                        state = PrescaledTimerState.IDLE
                        self.clear_deadline(id(timer))

    async def watch_pulse_train(self, pulse_gen):
        state = PulseTrainState.IDLE
        # wait for the timer to be stable
        await ClockCycles(pulse_gen.clk_i, 2)
        while True:
            await RisingEdge(pulse_gen.clk_i)
            counter = pulse_gen.pulse_counter.value.to_unsigned()
            match state:
                case PulseTrainState.IDLE:
                    if counter >= self.JUMP_THRES:
                        self.clear_busy(id(pulse_gen))
                        end_time = time.time() + counter / self.fpga_clock_freq
                        end_tick = self.timestamp + counter
                        state = PulseTrainState.WAIT_FOR_COUNTER
                        self.register_deadline(id(pulse_gen), end_time)
                        # make sure we do a few cycles after enabling
                        self.boost_timeout()
                    elif counter > 0:
                        self.mark_busy(id(pulse_gen))
                    else:
                        self.clear_busy(id(pulse_gen))
                case PulseTrainState.WAIT_FOR_COUNTER:
                    if counter == 0:
                        state = PulseTrainState.IDLE
                        self.clear_deadline(id(pulse_gen))
                    elif time.time() >= end_time and not self.pcap_busy():
                        self.advance_timestamp(end_tick)
                        pulse_gen.pulse_counter.value = 0
                        state = PulseTrainState.IDLE
                        self.clear_deadline(id(pulse_gen))

    async def watch_timestamp_queue(self, timestamp_queue):
        state = TimeStampQueueState.IDLE
        # wait for the queue to be stable
        await ClockCycles(timestamp_queue.clk_i, 2)
        while True:
            await RisingEdge(timestamp_queue.clk_i)
            read_valid = True if timestamp_queue.read_valid.value == 1 \
                              else False
            match state:
                case TimeStampQueueState.IDLE:
                    if read_valid:
                        timestamp = timestamp_queue.timestamp.value.to_unsigned()
                        next_timestamp = timestamp_queue.queue_pulse_ts.value.to_unsigned()
                        diff_tick = next_timestamp - timestamp
                        if diff_tick >= self.JUMP_THRES:
                            self.clear_busy(id(timestamp_queue))
                            end_time = time.time() + diff_tick / self.fpga_clock_freq
                            end_tick = self.timestamp + diff_tick
                            state = TimeStampQueueState.WAIT_FOR_COUNTER
                            self.register_deadline(id(timestamp_queue), end_time)
                            # make sure we do a few cycles after enabling
                            self.boost_timeout()
                        else:
                            self.mark_busy(id(timestamp_queue))
                    else:
                        self.clear_busy(id(timestamp_queue))
                case TimeStampQueueState.WAIT_FOR_COUNTER:
                    if not read_valid:
                        state = TimeStampQueueState.IDLE
                        self.clear_deadline(id(timestamp_queue))
                    elif time.time() >= end_time and not self.pcap_busy():
                        self.advance_timestamp(end_tick)
                        timestamp_queue.timestamp.value = next_timestamp
                        state = TimeStampQueueState.IDLE
                        self.clear_deadline(id(timestamp_queue))
