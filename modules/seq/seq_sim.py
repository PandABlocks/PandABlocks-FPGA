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
        if self._index == self._load_line - 1:
            self._index = 0
        else:
            self._index += 1
        self.next_line = self._make_line(self._index)

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

    def table_data(self, data):
        self._table[self._load_line][self._load_word] = data
        if self._load_word == 3:
            self._load_line += 1
            self._load_word = 0
        else:
            self._load_word += 1

    def table_lines(self, lines):
        if self._load_word == 0 and self._load_line == lines:
            self.table_ready = 1


WAIT_ENABLE = 0
LOAD_TABLE = 1
WAIT_TRIGGER = 2
PHASE1 = 3
PHASE2 = 4


class SeqSimulation(BlockSimulation):
    ENABLE, BITA, BITB, BITC, POSA, POSB, POSC, TABLE, PRESCALE, REPEATS, \
        ACTIVE, OUTA, OUTB, OUTC, OUTD, OUTE, OUTF, \
        TABLE_REPEAT, TABLE_LINE, LINE_REPEAT, STATE = PROPERTIES

    def __init__(self):
        # Next time we need to be called
        self.next_ts = None
        # A table
        self.table = SeqTable()
        # The current line
        self.current_line = None
        # TABLE Registers
        self.TABLE_LENGTH = 0
        self.TABLE_DATA = 0
        self.TABLE_START = 0

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

    def next_line(self):
        return self.table.next_line

    def current_triggers_met(self):
        return self.triggers_met(self.current_line)

    def next_triggers_met(self):
        return self.triggers_met(self.next_line())

    def last_line_repeat(self):
        return self.LINE_REPEAT == self.current_line.repeats

    def last_table_line(self):
        return self.last_line_repeat() and \
               self.TABLE_LINE == self.TABLE_LENGTH / 4

    def last_table_repeat(self):
        return self.last_table_line() and \
                self.TABLE_REPEAT == self.REPEATS

    def prescale(self):
        if self.PRESCALE > 0:
            return self.PRESCALE
        else:
            return 1

    def current_time1(self):
        return self.prescale() * self.current_line.time1

    def current_time2(self):
        if self.current_line.time2 == 0:
            return self.prescale()
        else:
            return self.prescale() * self.current_line.time2

    def next_time1(self):
        return self.prescale() * self.next_line().time1

    def next_time2(self):
        if self.next_line().time2 == 0:
            return self.prescale()
        else:
            return self.prescale() * self.next_line().time2

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(SeqSimulation, self).on_changes(ts, changes)

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)
        state = self.STATE

        if changes.get("TABLE_START", None) == 1:
            # Loading a table stops everything
            self.table.table_start()
            self.set_outputs(0)
            state = LOAD_TABLE
        elif changes.get(NAMES.ENABLE, None) == False:
            # If we are disabled at any point stop and wait for enable
            self.ACTIVE = 0
            self.set_outputs(0)
            if self.STATE != LOAD_TABLE:
                # Not currently loading a table, so reset it and drop back to WAIT_ENABLE
                self.table.reset()
                state = WAIT_ENABLE
        else:
            if self.STATE == WAIT_ENABLE:
                # If we get an enable or we are still active after a table rewrite
                if changes.get(NAMES.ENABLE, None) == 1 or self.ACTIVE:
                    if self.table.table_ready:
                        if not self.next_triggers_met():
                            state = WAIT_TRIGGER
                        elif self.next_line().time1:
                            # Do phase 1
                            self.next_ts = ts + self.next_time1()
                            self.set_outputs(self.next_line().out1)
                            state = PHASE1
                        else:
                            # Do phase 2
                            self.next_ts = ts + self.next_time2()
                            self.set_outputs(self.next_line().out2)
                            state = PHASE2
                        self.TABLE_REPEAT = 1
                        self.TABLE_LINE = 1
                        self.LINE_REPEAT = 1
                        self.ACTIVE = 1
                        self.current_line = self.next_line()
                        self.table.load_next()
            elif self.STATE == LOAD_TABLE:
                # And while we're in this state we ignore everything apart from
                # table commands
                if self.table.table_ready:
                    state = WAIT_ENABLE
                elif "TABLE_DATA" in changes:
                    self.table.table_data(changes["TABLE_DATA"])
                elif "TABLE_LENGTH" in changes:
                    self.table.table_lines(changes["TABLE_LENGTH"] / 4)
                    self.table.reset()
                    return ts + 1
            elif self.STATE == WAIT_TRIGGER:
                if self.current_triggers_met():
                    if self.current_line.time1:
                        # Do phase 1
                        self.next_ts = ts + self.current_time1()
                        self.set_outputs(self.current_line.out1)
                        state = PHASE1
                    else:
                        # Do phase 2
                        self.next_ts = ts + self.current_time2()
                        self.set_outputs(self.current_line.out2)
                        state = PHASE2
            elif self.STATE == PHASE1:
                # If doing phase 1, check if time has expired
                if ts >= self.next_ts:
                    # Do phase 2
                    self.next_ts = ts + self.current_time2()
                    self.set_outputs(self.current_line.out2)
                    state = PHASE2
            elif self.STATE == PHASE2:
                # If doing phase 2, check if time has expired
                if ts >= self.next_ts:
                    if self.last_table_repeat():
                        # If table is finished then we're done
                        self.ACTIVE = 0
                        self.set_outputs(0)
                        self.table.reset()
                        state = WAIT_ENABLE
                    elif self.last_line_repeat():
                        if self.last_table_line():
                            # Finished the last line in the table, advance repeats
                            self.TABLE_LINE = 1
                            self.TABLE_REPEAT += 1
                        else:
                            # Finished this line, move to the next
                            self.TABLE_LINE += 1
                        self.LINE_REPEAT = 1
                        if not self.next_triggers_met():
                            state = WAIT_TRIGGER
                        elif self.next_line().time1:
                            # Do phase 1
                            self.next_ts = ts + self.next_time1()
                            self.set_outputs(self.next_line().out1)
                            state = PHASE1
                        else:
                            # Do phase 2
                            self.next_ts = ts + self.next_time2()
                            self.set_outputs(self.next_line().out2)
                            state = PHASE2
                        # Have to advance to the next line of the table
                        self.current_line = self.next_line()
                        self.table.load_next()
                    else:
                        # Repeat the current line again
                        self.LINE_REPEAT += 1
                        if not self.current_triggers_met():
                            state = WAIT_TRIGGER
                        elif self.current_line.time1:
                            # Do phase 1
                            self.next_ts = ts + self.current_time1()
                            self.set_outputs(self.current_line.out1)
                            state = PHASE1
                        else:
                            # Do phase 2
                            self.next_ts = ts + self.current_time2()
                            self.set_outputs(self.current_line.out2)
                            state = PHASE2

        if state != self.STATE:
            # We updated statemachine, might need another tick to check the
            # next state
            self.STATE = state
            return ts + 1
        elif self.next_ts > ts:
            return self.next_ts
