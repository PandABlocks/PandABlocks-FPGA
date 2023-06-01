from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING
import numpy

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
    def __init__(self):
        # Table of data as described in config parameter TABLE
        self._table = numpy.zeros(shape=(512, 4), dtype=numpy.uint32)
        # Line of the table, 0..511
        self._load_line = 0
        # Word of a line, 0..3
        self._load_word = 0
        # The current table line index
        self._index = 0
        # If the table is ready
        self.table_ready = 0
        # The next frame
        self.next_line = SeqLine()

    def reset(self):
        self._index = 0
        self.next_line = self._make_line(self._index)

    def load_next(self):
        if self._index == self.n_lines - 1:
            self._index = 0
        else:
            self._index += 1

        self.next_line = self._make_line(self._index)

    @property
    def last(self):
        return self._index == self.n_lines - 1

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

    def table_start(self):
        self.table_ready = 0
        self._load_line = 0
        self._load_word = 0
        self.reset()

    def table_data(self, data):
        self._table[self._load_line][self._load_word] = data
        if self._load_word == 3:
            self._load_line += 1
            self._load_word = 0
        else:
            self._load_word += 1

        # make sure the next line is up to date with what's written
        self.next_line = self._make_line(self._index)

    def table_lines(self, lines):
        if lines > 0:
            self.n_lines = lines
            self.table_ready = 1


# Table states
TABLE_INVALID, TABLE_LAST, TABLE_CONT, TABLE_LOADING = range(4)

# Table errors
TABLE_ERROR_OK = 0
TABLE_ERROR_UNDERRUN = 1
TABLE_ERROR_OVERRUN = 2


class SeqDoubleTable(object):
    def __init__(self):
        self.tables = [SeqTable(), SeqTable()]
        self.states = [TABLE_INVALID, TABLE_INVALID]
        self.rd_index = 0
        self.wr_index = 0
        self.zero_count = 0
        self.has_written_last = False
        self.error = 0

    @property
    def can_write_next(self):
        return self.rd_index != self.wr_index and not self.has_written_last

    @property
    def next_expected(self):
        return self.states[self.rd_index] == TABLE_CONT

    @property
    def table_ready(self):
        return self.tables[self.rd_index].table_ready

    def reset_tables(self):
        if self.states[self.rd_index] != TABLE_LAST:
            self.states[self.rd_index] = TABLE_INVALID

        self.states[self.rd_index ^ 1] = TABLE_INVALID
        self.wr_index = self.rd_index
        self.tables[0].reset()
        self.tables[1].reset()

    def reset_error(self):
        self.error = 0

    def load_next(self):
        was_last = self.tables[self.rd_index].last
        self.tables[self.rd_index].load_next()
        if self.states[self.rd_index] in (TABLE_INVALID, TABLE_LOADING):
            self.error = TABLE_ERROR_UNDERRUN

        if was_last and self.states[self.rd_index] == TABLE_CONT:
            if self.rd_index ^ 1 == self.wr_index \
                    and self.states[self.wr_index] != TABLE_LAST:
                self.error = TABLE_ERROR_UNDERRUN

            self.rd_index ^= 1

    @property
    def last(self):
        return self.tables[self.rd_index].last

    def table_start(self):
        self.tables[self.wr_index].table_start()
        self.states[self.wr_index] = TABLE_LOADING

    def table_data(self, data):
        if data == 0:
            self.zero_count += 1
        else:
            self.zero_count = 0

        self.tables[self.wr_index].table_data(data)

    @property
    def next_line(self):
        return self.tables[self.rd_index].next_line

    @property
    def table_ready(self):
        return self.tables[self.rd_index].table_ready

    def table_lines(self, lines):
        has_cont_mark = self.zero_count >= 4
        corrected_lines = lines - 1 if has_cont_mark else lines
        self.tables[self.wr_index].table_lines(corrected_lines)
        if corrected_lines <= 0:
            self.states[self.wr_index] = TABLE_INVALID
            self.has_written_last = True
        elif has_cont_mark:
            self.states[self.wr_index] = TABLE_CONT
            self.wr_index ^= 1
            self.has_written_last = False
        else:
            self.states[self.wr_index] = TABLE_LAST
            self.has_written_last = True


UNREADY = 0
WAIT_ENABLE = 1
WAIT_TRIGGER = 2
PHASE1 = 3
PHASE2 = 4


class SeqSimulation(BlockSimulation):
    ENABLE, BITA, BITB, BITC, POSA, POSB, POSC, TABLE, TABLE_START, \
        TABLE_DATA, TABLE_LENGTH, PRESCALE, REPEATS, \
        ACTIVE, OUTA, OUTB, OUTC, OUTD, OUTE, OUTF, \
        TABLE_REPEAT, TABLE_LINE, LINE_REPEAT, STATE, HEALTH, \
        CAN_WRITE_NEXT = PROPERTIES

    def __init__(self):
        # Next time we need to be called
        self.next_ts = None
        # A table
        self.table = SeqDoubleTable()
        # The current line
        self.current_line = None
        self.current_next_table_expected = False
        self.current_last_frame_in_table = False
        self.state2function = {
            UNREADY: self.unready_state,
            WAIT_ENABLE: self.wait_enable_state,
            WAIT_TRIGGER: self.wait_trigger,
            PHASE1: self.phase1_state,
            PHASE2: self.phase2_state
        }

    def handle_table_loading(self, ts, changes):
        if NAMES.TABLE_START in changes:
            self.table.table_start()

        if NAMES.TABLE_DATA in changes:
            self.table.table_data(self.TABLE_DATA)

        if NAMES.TABLE_LENGTH in changes:
            self.table.table_lines(self.TABLE_LENGTH / 4)

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
        return self.last_line_repeat and self.current_last_frame_in_table

    def last_table_repeat(self):
        return self.last_table_line and self.TABLE_REPEAT != 0 \
            and self.TABLE_REPEAT == self.REPEATS \
            and not self.current_next_table_expected

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
    def next_time1(self):
        return self.prescale * self.next_line.time1

    @property
    def next_time2(self):
        if self.next_line.time2 == 0:
            return self.prescale
        else:
            return self.prescale * self.next_line.time2

    def reset_repeat_count(self, val):
        self.TABLE_REPEAT = val
        self.TABLE_LINE = val
        self.LINE_REPEAT = val

    def unready_state(self, ts, changes):
        # And while we're in this state we ignore everything apart from
        # table commands
        if self.table.table_ready:
            self.STATE = WAIT_ENABLE

        if NAMES.TABLE_START in changes:
            self.reset_repeat_count(0)

    def wait_enable_state(self, ts, changes):
        if not self.table.table_ready:
            self.STATE = UNREADY
        elif NAMES.TABLE_START in changes and not self.table.can_write_next:
            self.reset_repeat_count(0)
        elif changes.get(NAMES.ENABLE, None) == 1:
            if not self.next_triggers_met:
                self.STATE = WAIT_TRIGGER
            elif self.next_line.time1:
                # Do phase 1
                self.next_ts = ts + self.next_time1
                self.set_outputs(self.next_line.out1)
                self.STATE = PHASE1
            else:
                # Do phase 2
                self.next_ts = ts + self.next_time2
                self.set_outputs(self.next_line.out2)
                self.STATE = PHASE2

            self.reset_repeat_count(1)
            self.HEALTH = TABLE_ERROR_OK
            self.ACTIVE = 1
            self.current_line = self.next_line
            self.current_next_table_expected = self.table.next_expected
            self.current_last_frame_in_table = self.table.last
            self.table.load_next()

    def wait_trigger(self, ts, changes):
        if self.current_triggers_met:
            if self.current_line.time1:
                # Do phase 1
                self.next_ts = ts + self.current_time1
                self.set_outputs(self.current_line.out1)
                self.STATE = PHASE1
            else:
                # Do phase 2
                self.next_ts = ts + self.current_time2
                self.set_outputs(self.current_line.out2)
                self.STATE = PHASE2

    def phase1_state(self, ts, changes):
        # If doing phase 1, check if time has expired
        if ts >= self.next_ts:
            # Do phase 2
            self.next_ts = ts + self.current_time2
            self.set_outputs(self.current_line.out2)
            self.STATE = PHASE2

    def phase2_state(self, ts, changes):
        # If doing phase 2, check if time has expired
        if ts >= self.next_ts:
            if self.last_table_repeat():
                # If table is finished then we're done
                self.ACTIVE = 0
                self.set_outputs(0)
                self.STATE = WAIT_ENABLE
            elif self.last_line_repeat:
                if self.last_table_line:
                    self.LINE_REPEAT = 1
                    # Finished the last line in the table, advance repeats
                    self.TABLE_LINE = 1
                    if not self.current_next_table_expected:
                        self.TABLE_REPEAT += 1
                else:
                    self.LINE_REPEAT = 1
                    # Finished this line, move to the next
                    self.TABLE_LINE += 1

                if not self.next_triggers_met:
                    self.STATE = WAIT_TRIGGER
                elif self.next_line.time1:
                    # Do phase 1
                    self.next_ts = ts + self.next_time1
                    self.set_outputs(self.next_line.out1)
                    self.STATE = PHASE1
                else:
                    # Do phase 2
                    self.next_ts = ts + self.next_time2
                    self.set_outputs(self.next_line.out2)
                    self.STATE = PHASE2

                # Have to advance to the next line of the table
                self.current_line = self.next_line
                self.current_next_table_expected = self.table.next_expected
                self.current_last_frame_in_table = self.table.last
                self.table.load_next()
            else:
                # Repeat the current line again
                self.LINE_REPEAT += 1
                if not self.current_triggers_met:
                    self.STATE = WAIT_TRIGGER
                elif self.current_line.time1:
                    # Do phase 1
                    self.next_ts = ts + self.current_time1
                    self.set_outputs(self.current_line.out1)
                    self.STATE = PHASE1
                else:
                    # Do phase 2
                    self.next_ts = ts + self.current_time2
                    self.set_outputs(self.current_line.out2)
                    self.STATE = PHASE2

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(SeqSimulation, self).on_changes(ts, changes)
        running = self.STATE != UNREADY and self.STATE != WAIT_ENABLE
        start_not_expected = changes.get(NAMES.TABLE_START, None) == 1 \
            and running and not self.table.can_write_next

        if changes.get(NAMES.ENABLE, None) == 0:
            self.set_outputs(0)
            self.ACTIVE = 0
            self.table.reset_tables()
            if self.table.table_ready:
                self.STATE = WAIT_ENABLE

        elif self.table.error:
            self.set_outputs(0)
            self.ACTIVE = 0
            self.STATE = UNREADY
            self.HEALTH = self.table.error
            self.table.reset_error()

        elif start_not_expected:
            self.set_outputs(0)
            self.ACTIVE = 0
            self.STATE = UNREADY
            self.HEALTH = TABLE_ERROR_OVERRUN
            self.reset_repeat_count(0)

        else:
            self.state2function[self.STATE](ts, changes)

        self.handle_table_loading(ts, changes)
        self.CAN_WRITE_NEXT = self.table.can_write_next
        return ts + 1
