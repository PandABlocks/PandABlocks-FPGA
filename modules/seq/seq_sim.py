import os

from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING
import numpy

from collections import deque

NAMES, PROPERTIES = properties_from_ini(__file__, "seq.block.ini")


class SeqLine(object):
    repeats = None
    trigger = None
    position = None
    time1 = None
    out1 = None
    time2 = None
    out2 = None

    def __str__(self):
        return f"SeqLine(repeats={self.repeats}, trigger={self.trigger}, " \
               f"position={self.position}, out1={self.out1}, time1={self.time1}, " \
               f"out2={self.out2}, time2={self.time2})"


class SeqTable(object):
    def __init__(self, n_entries=4096):
        # Table of data as described in config parameter TABLE
        self.n_entries = n_entries
        self._table = numpy.zeros(shape=(self.n_entries, 4), dtype=numpy.uint32)
        self._last = [False] * self.n_entries
        self.read_index = 0
        self.write_index = 0
        self.write_dindex = 0
        # The next frame
        self.next_line = SeqLine()
        self.next_last = False
        self.wrapping_mode = False
        self.resetting = False
        self.reset()

    def reset(self, hard=False):
        self.read_index = 0
        if not self.wrapping_mode or hard:
            self.write_index = 0
            self.write_dindex = 0
            self._table.fill(0)

        self.next_line = self._make_line(self.read_index)
        self.next_last = False
        self.resetting = True

    def __len__(self):
        if self.wrapping_mode:
            return self.write_index
        else:
            return self.write_index - self.read_index

    @property
    def table_ready(self):
        return not self.empty()

    def empty(self):
        return self.write_index == self.read_index

    def full(self):
        return (self.write_index + 1) % self.n_entries == self.read_index

    def add_dword(self, data, last):
        if not self.full():
            self._table[self.write_index][self.write_dindex] = data
            self.write_dindex += 1
            if self.write_dindex >= 4:
                self._last[self.write_index] = last
                if self.write_index == self.read_index:
                    self.next_line = self._make_line(self.read_index)
                    self.next_last = self._last[self.read_index]

                self.write_index = (self.write_index + 1) % self.n_entries
                self.write_dindex = 0

    def load_next(self):
        if not self.empty():
            self.read_index = (self.read_index + 1) % self.n_entries
            if self.wrapping_mode and self.read_index == self.write_index:
                self.read_index = 0

        self.next_line = self._make_line(self.read_index)
        self.next_last = self._last[self.read_index]

    def _make_line(self, index):
        line = SeqLine()
        # 15:0    REPEATS
        line.repeats = self._table[index][0] & 0xffff
        # 19:16   TRIGGER     enum
        line.trigger = (self._table[index][0] >> 16) & 0xf
        # 63:32   POSITION
        line.position = self._table[index][1]
        # 95:64 TIME1
        line.time1 = self._table[index][2]
        # 20:20   OUTA1
        # 21:21   OUTB1
        # 22:22   OUTC1
        # 23:23   OUTD1
        # 24:24   OUTE1
        # 25:25   OUTF1
        line.out1 = (self._table[index][0] >> 20) & 0x3f
        # 127:96  TIME2
        line.time2 = self._table[index][3]
        # 26:26   OUTA2
        # 27:27   OUTB2
        # 28:28   OUTC2
        # 29:29   OUTD2
        # 30:30   OUTE2
        # 31:31   OUTF2
        line.out2 = (self._table[index][0] >> 26) & 0x3f
        return line


# Table errors
TABLE_ERROR_OK = 0
TABLE_ERROR_UNDERRUN = 1
TABLE_ERROR_OVERRUN = 2

# Sequencer states
UNREADY = 0
WAIT_ENABLE = 1
WAIT_TRIGGER = 2
PHASE1 = 3
PHASE2 = 4

# Table modes
TABLE_MODE_INIT = 0
TABLE_MODE_FIXED = 1
TABLE_MODE_STREAMING = 2
TABLE_MODE_STREAMING_LAST = 3


class SeqSimulation(BlockSimulation):
    ENABLE, BITA, BITB, BITC, POSA, POSB, POSC, TABLE, TABLE_ADDRESS, \
        TABLE_LENGTH, PRESCALE, REPEATS, \
        ACTIVE, OUTA, OUTB, OUTC, OUTD, OUTE, OUTF, \
        TABLE_REPEAT, TABLE_LINE, LINE_REPEAT, STATE, HEALTH = PROPERTIES

    def __init__(self):
        # Next time we need to be called
        self.next_ts = None
        # A table
        self.table = SeqTable()
        # The current line
        self.current_line = None
        self.current_last_frame_in_table = False
        self.state2function = {
            UNREADY: self.unready_state,
            WAIT_ENABLE: self.wait_enable_state,
            WAIT_TRIGGER: self.wait_trigger,
            PHASE1: self.phase1_state,
            PHASE2: self.phase2_state
        }
        self.data = deque()
        self.data_last = deque()
        self.data_reset = False
        self.len = 0
        self.error_detected = TABLE_ERROR_OK
        self.table_frames = 0
        self.more_flag = False
        self.table_mode = TABLE_MODE_INIT

    def set_outputs(self, outputs):
        self.OUTA = outputs & 1
        self.OUTB = (outputs >> 1) & 1
        self.OUTC = (outputs >> 2) & 1
        self.OUTD = (outputs >> 3) & 1
        self.OUTE = (outputs >> 4) & 1
        self.OUTF = (outputs >> 5) & 1

    def triggers_met(self, line):
        # If waiting for triggers check them here
        position = line.position
        conditions = [
            True,
            self.BITA == 0, self.BITA == 1,
            self.BITB == 0, self.BITB == 1,
            self.BITC == 0, self.BITC == 1,
            self.POSA >= position, self.POSA <= position,
            self.POSB >= position, self.POSB <= position,
            self.POSC >= position, self.POSC <= position,
            True, True, True,
        ]
        return conditions[line.trigger]

    @property
    def next_line(self):
        return self.table.next_line

    @property
    def next_last(self):
        return self.table.next_last

    @property
    def current_triggers_met(self):
        return self.triggers_met(self.current_line)

    @property
    def next_triggers_met(self):
        return self.triggers_met(self.next_line)

    @property
    def last_line_repeat(self):
        return self.LINE_REPEAT != 0 \
            and self.LINE_REPEAT == self.current_line.repeats

    @property
    def last_table_line(self):
        return self.last_line_repeat and \
            ((not self.streaming_mode and
              self.TABLE_LINE == self.table_frames) or self.current_last)

    @property
    def last_table_repeat(self):
        return self.last_table_line and \
            ((not self.streaming_mode and
              self.TABLE_REPEAT != 0 and
              self.TABLE_REPEAT == self.REPEATS) or self.streaming_mode)

    @property
    def prescale(self):
        if self.PRESCALE > 0:
            return self.PRESCALE
        else:
            return 1

    @property
    def current_time1(self):
        return self.prescale * self.current_line.time1

    @property
    def current_time2(self):
        if self.current_line.time2 == 0:
            return self.prescale
        else:
            return self.prescale * self.current_line.time2

    @property
    def streaming_mode(self):
        return self.table_mode in (TABLE_MODE_STREAMING,
                                   TABLE_MODE_STREAMING_LAST)

    def reset_repeat_count(self, val):
        self.TABLE_REPEAT = val
        self.TABLE_LINE = val
        self.LINE_REPEAT = val

    def unready_state(self, ts, changes):
        # And while we're in this state we ignore everything apart from
        # table commands
        if self.table.table_ready:
            self.STATE = WAIT_ENABLE

        if NAMES.TABLE_LENGTH in changes:
            self.reset_repeat_count(0)

    def wait_enable_state(self, ts, changes):
        if not self.table.table_ready:
            if not self.table.resetting:
                self.STATE = UNREADY
            else:
                self.table.resetting = False

        elif NAMES.TABLE_LENGTH in changes:
            self.reset_repeat_count(0)
        elif changes.get(NAMES.ENABLE, None) == 1:
            self.goto_next_state(ts, load_next=True, consider_triggers=True)
            self.reset_repeat_count(1)
            self.HEALTH = TABLE_ERROR_OK
            self.ACTIVE = 1

    def wait_trigger(self, ts, changes):
        if self.current_triggers_met:
            self.goto_next_state(ts, load_next=False, consider_triggers=False)

    def phase1_state(self, ts, changes):
        # If doing phase 1, check if time has expired
        if ts >= self.next_ts:
            self.goto_phase_2(ts)

    def phase2_state(self, ts, changes):
        # If doing phase 2, check if time has expired
        if ts >= self.next_ts:
            if self.last_table_repeat:
                print('last_table_repeat')
                # If table is finished then we're done
                self.ACTIVE = 0
                self.set_outputs(0)
                self.STATE = \
                    WAIT_ENABLE if self.table.wrapping_mode else UNREADY
            elif self.last_line_repeat:
                print('last_line_repeat')
                if self.last_table_line:
                    print('last_table_line')
                    self.TABLE_LINE = 1
                    if not self.streaming_mode:
                        self.TABLE_REPEAT += 1
                else:
                    self.TABLE_LINE += 1

                self.LINE_REPEAT = 1
                self.goto_next_state(
                    ts, load_next=True, consider_triggers=True)
            else:
                # Repeat the current line again
                self.LINE_REPEAT += 1
                self.goto_next_state(
                    ts, load_next=False, consider_triggers=True)

    def goto_phase_1(self, ts):
        self.next_ts = ts + self.current_time1
        self.set_outputs(self.current_line.out1)
        self.STATE = PHASE1

    def goto_phase_2(self, ts):
        self.next_ts = ts + self.current_time2
        self.set_outputs(self.current_line.out2)
        self.STATE = PHASE2

    def goto_next_state(self, ts, load_next=False, consider_triggers=False):
        print(f'goto_next_state: ts={ts}, load_next={load_next}')
        if load_next:
            if self.table.empty():
                self.error_detected = TABLE_ERROR_UNDERRUN
                self.reset()
                return

            self.current_line = self.next_line
            self.current_last = self.next_last
            self.table.load_next()

        if consider_triggers and not self.current_triggers_met:
            self.STATE = WAIT_TRIGGER
        elif self.current_line.time1:
            self.goto_phase_1(ts)
        else:
            self.goto_phase_2(ts)

    def load_data(self):
        file_path = os.path.join(
            os.path.dirname(__file__), 'tests_assets',
            f'{self.TABLE_ADDRESS}.txt')
        with open(file_path, 'r') as f:
            lines = list(f)[1:]
        new_data = [int(line, 16) if line.startswith('0x') else
                    int(line) for line in lines]
        data_last = [False] * len(new_data)
        data_last[-1] = self.table_mode == TABLE_MODE_STREAMING_LAST
        self.data.extend([(None, 0)] * 6)
        self.data.extend(zip(new_data, data_last))

    def handle_table_write(self, ts, changes):
        if self.data:
            item = self.data.popleft()
            if item[0] is not None:
                self.table.add_dword(item[0], item[1])

        if NAMES.TABLE_LENGTH in changes:
            if self.TABLE_LENGTH:
                if self.table_mode != TABLE_MODE_INIT and \
                        self.table_mode != TABLE_MODE_STREAMING:
                    self.error_detected = TABLE_ERROR_OVERRUN
                else:
                    self.len = self.TABLE_LENGTH & 0x7fffffff
                    self.table_frames = self.len >> 2
                    self.more_flag = bool(self.TABLE_LENGTH & 0x80000000)
                    if self.table_mode == TABLE_MODE_INIT:
                        self.table_mode = TABLE_MODE_STREAMING \
                            if self.more_flag else TABLE_MODE_FIXED
                    elif self.table_mode == TABLE_MODE_STREAMING:
                        if not self.more_flag:
                            self.table_mode = TABLE_MODE_STREAMING_LAST
                    if self.table_mode == TABLE_MODE_FIXED:
                        assert self.len < 4096, \
                            "Tables bigger than 4095 in fixed mode are not " \
                            "supported in simulation"
                        self.table.wrapping_mode = True
                    else:
                        self.table.wrapping_mode = False

                    self.load_data()
            else:
                self.data = deque()
                self.table.reset(hard=True)
                self.table_mode = TABLE_MODE_INIT

    def reset(self):
        self.set_outputs(0)
        self.ACTIVE = 0
        if self.STATE != WAIT_ENABLE and self.STATE != UNREADY:
            if self.table.wrapping_mode and self.error_detected == TABLE_ERROR_OK:
                self.STATE = WAIT_ENABLE
                self.table.reset()
            else:
                self.STATE = UNREADY
                self.data = deque()
                self.table.reset(hard=True)
                self.table_mode = TABLE_MODE_INIT

        if self.error_detected != TABLE_ERROR_OK:
            self.HEALTH = self.error_detected
            self.error_detected = TABLE_ERROR_OK

        self.reset_repeat_count(0)

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(SeqSimulation, self).on_changes(ts, changes)
        if changes.get(NAMES.ENABLE, None) == 0 or \
                self.error_detected != TABLE_ERROR_OK:
            self.reset()
        else:
            print(f'{ts}: before state={self.STATE}, ', end='')
            print(f'line={self.current_line}, health={self.HEALTH}, ', end='')
            print(f'LINE_REPEAT={self.LINE_REPEAT}, ', end='')
            print(f'table write_index={self.table.write_index}, ', end='')
            print(f'read_index={self.table.read_index}')
            self.state2function[self.STATE](ts, changes)
            print(f'{ts}: after state={self.STATE}, ', end='')
            print(f'line={self.current_line}, health={self.HEALTH}, ', end='')
            print(f'LINE_REPEAT={self.LINE_REPEAT}, ', end='')
            print(f'table write_index={self.table.write_index}, ', end='')
            print(f'read_index={self.table.read_index}')

        self.handle_table_write(ts, changes)
        return ts + 1
