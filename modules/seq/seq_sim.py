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


class SeqTable(object):
    def __init__(self, n_entries=4096):
        # Table of data as described in config parameter TABLE
        self.n_entries = n_entries
        self._table = numpy.zeros(shape=(self.n_entries, 4), dtype=numpy.uint32)
        self.read_index = 0
        self.write_index = 0
        self.write_dindex = 0
        # The next frame
        self.next_line = SeqLine()
        self.reset()

    def reset(self):
        self.read_index = 0
        self.write_index = 0
        self.write_dindex = 0
        self._table.fill(0)
        self.next_line = self._make_line(self.read_index)

    @property
    def table_ready(self):
        return not self.empty()

    def empty(self):
        return self.write_index == self.read_index

    def full(self):
        return (self.write_index + 1) % self.n_entries == self.read_index

    def add_dword(self, data):
        if not self.full():
            self._table[self.write_index][self.write_dindex] = data
            self.write_dindex += 1
            if self.write_dindex >= 4:
                if self.write_index == self.read_index:
                    self.next_line = self._make_line(self.read_index)
                self.write_index = (self.write_index + 1) % self.n_entries
                self.write_dindex = 0

    def load_next(self):
        if not self.empty():
            self.read_index = (self.read_index + 1) % self.n_entries

        self.next_line = self._make_line(self.read_index)

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


# Table states
TABLE_INVALID, TABLE_LAST, TABLE_CONT, TABLE_LOADING = range(4)

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
        self.data_repeats = 1
        self.data_reset = False
        self.new_data = []
        self.len = 0
        self.saved_len = 0
        self.len_taken = True
        self.error_detected = TABLE_ERROR_OK
        self.done = False
        self.table_frames = 0
        self.last_table = False
        self.last_table_seen = False

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
        return self.last_line_repeat and self.TABLE_LINE == self.table_frames

    @property
    def last_table_repeat(self):
        return self.last_table_line and self.TABLE_REPEAT != 0 \
            and self.TABLE_REPEAT == self.REPEATS and self.last_table

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

    def resetting_state(self, ts, changes):
        if not self.data:
            self.STATE = UNREADY

    def wait_enable_state(self, ts, changes):
        if not self.table.table_ready:
            self.STATE = UNREADY
        elif NAMES.TABLE_LENGTH in changes:
            self.reset_repeat_count(0)
        elif changes.get(NAMES.ENABLE, None) == 1:
            self.goto_next_state(ts, load_next=True, consider_triggers=True)
            self.reset_repeat_count(1)
            self.HEALTH = TABLE_ERROR_OK
            self.table_frames = (self.len & 0x7fffffff) >> 2
            self.last_table = False if self.len >> 31 else True
            self.len_taken = True
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
                # If table is finished then we're done
                self.ACTIVE = 0
                self.set_outputs(0)
                self.STATE = UNREADY
                self.done = True
            elif self.last_line_repeat:
                if self.last_table_line:
                    if self.last_table:
                        self.TABLE_REPEAT += 1
                    self.TABLE_LINE = 1
                    self.table_frames = (self.len & 0x7fffffff) >> 2
                    self.last_table = False if self.len >> 31 else True
                    self.len_taken = True
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
        if load_next:
            if self.table.empty():
                self.error_detected = TABLE_ERROR_UNDERRUN
                self.reset()
                return

            self.current_line = self.next_line
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
        self.new_data = new_data
        self.data.extend([None] * 6)
        self.data.extend(new_data)

    def handle_table_write(self, ts, changes):
        if not self.data and self.last_table and \
                (self.data_repeats < self.REPEATS or self.REPEATS == 0):
            self.data_repeats += 1
            self.data.extend(self.new_data)
            self.data.append(None)

        if self.data:
            item = self.data.popleft()
            if item is not None:
                self.table.add_dword(item)

        if self.len_taken and self.saved_len:
            self.len = self.saved_len
            self.saved_len = 0
            self.load_data()

        if NAMES.TABLE_LENGTH in changes:
            if self.TABLE_LENGTH:
                if self.last_table_seen or (not self.len_taken and
                                            self.saved_len):
                    self.error_detected = TABLE_ERROR_OVERRUN
                elif not self.len_taken:
                    self.saved_len = self.TABLE_LENGTH
                else:
                    self.len = self.TABLE_LENGTH
                    self.len_taken = False
                    self.load_data()

                self.last_table_seen = \
                    False if self.TABLE_LENGTH & 0x80000000 else True
            else:
                self.data = deque()
                self.new_data = []
                self.table.reset()
                self.data_repeats = 1
                self.saved_len = 0
                self.last_table_seen = False

    def reset(self):
        self.last_table = False
        self.table.reset()
        self.set_outputs(0)
        self.ACTIVE = 0
        if self.STATE != WAIT_ENABLE:
            self.STATE = UNREADY
        if self.error_detected != TABLE_ERROR_OK:
            self.HEALTH = self.error_detected
            self.error_detected = TABLE_ERROR_OK
        self.reset_repeat_count(0)
        self.data = deque()

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(SeqSimulation, self).on_changes(ts, changes)
        if changes.get(NAMES.ENABLE, None) == 0 or \
                self.error_detected != TABLE_ERROR_OK:
            self.reset()
        else:
            self.state2function[self.STATE](ts, changes)

        self.handle_table_write(ts, changes)
        return ts + 1
