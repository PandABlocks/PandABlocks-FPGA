import numpy

from common.python.pandablocks.block import Block
from collections import deque


WAIT_ENABLE = 0
LOAD_TABLE = 1
WAIT_TRIGGER = 2
PHASE1 = 3
PHASE2 = 4

OK = 0
ERR_LENGTH = 1


class Seq(Block):
    def __init__(self):
        # Table of data as described in config parameter TABLE
        self.table = numpy.zeros(shape=(512, 4), dtype=numpy.uint32)
        # Line of the table, 0..511
        self.load_line = 0
        # Word of a line, 0..3
        self.load_word = 0
        # Length of the table
        self.table_length = 0
        # Next timestamp for phase
        self.next_ts = None

    def do_enable(self):
        if self.table_length > 0:
            self.TABLE_REPEAT = 1
            self.TABLE_LINE = 1
            self.LINE_REPEAT = 1
            self.ACTIVE = 1
            self.next_ts = None
            return WAIT_TRIGGER
        else:
            return WAIT_ENABLE

    def do_disable(self):
        self.ACTIVE = 0
        self.set_outputs(0)
        return WAIT_ENABLE

    def do_table_start(self):
        self.load_line = 0
        self.load_word = 0
        return LOAD_TABLE

    def do_table_data(self, data):
        self.table[self.load_line][self.load_word] = data
        if self.load_word == 3:
            self.load_line += 1
            self.load_word = 0
        else:
            self.load_word += 1
        return LOAD_TABLE

    def do_table_length(self, length):
        assert self.load_word == 0, "Not got a complete line"
        assert self.load_line * 4 == length, \
            "Only got %d lines, not %d" % (self.load_line, length)
        self.table_length = self.load_line
        return WAIT_ENABLE

    def do_check_trigger(self, ts):
        # 63:32   POSITION
        position = self.table[self.TABLE_LINE-1][1]
        # 19:16   TRIGGER     enum
        trigger = (self.table[self.TABLE_LINE-1][0] >> 16) & 0xf
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
        if conditions[trigger]:
            return self.do_phase_1(ts)
        else:
            return WAIT_TRIGGER

    def set_outputs(self, outputs):
        self.OUTA = outputs & 1
        self.OUTB = (outputs >> 1) & 1
        self.OUTC = (outputs >> 2) & 1
        self.OUTD = (outputs >> 3) & 1
        self.OUTE = (outputs >> 4) & 1
        self.OUTF = (outputs >> 5) & 1

    def do_phase_1(self, ts):
        # 95:64 TIME1
        time1 = self.table[self.TABLE_LINE-1][2] * self.PRESCALE
        if time1 == 0:
            # Must specify time1
            time1 = 1
        # 20:20   OUTA1
        # 21:21   OUTB1
        # 22:22   OUTC1
        # 23:23   OUTD1
        # 24:24   OUTE1
        # 25:25   OUTF1
        outputs = (self.table[self.TABLE_LINE-1][0] >> 20) & 0x3f
        self.set_outputs(outputs)
        self.next_ts = ts + time1
        return PHASE1

    def do_phase_2(self, ts):
        # 127:96  TIME2
        time2 = self.table[self.TABLE_LINE-1][3] * self.PRESCALE
        if time2 > 0:
            # 26:26   OUTA2
            # 27:27   OUTB2
            # 28:28   OUTC2
            # 29:29   OUTD2
            # 30:30   OUTE2
            # 31:31   OUTF2
            outputs = (self.table[self.TABLE_LINE-1][0] >> 26) & 0x3f
            self.set_outputs(outputs)
            self.next_ts = ts + time2
            return PHASE2
        else:
            return self.do_next_line(ts)

    def do_next_line(self, ts):
        self.next_ts = None
        # 15:0    REPEATS
        repeats = self.table[self.TABLE_LINE-1][0] & 0xffff
        if self.LINE_REPEAT < repeats:
            self.LINE_REPEAT += 1
        elif self.TABLE_LINE < self.table_length:
            self.LINE_REPEAT = 1
            self.TABLE_LINE += 1
        elif self.TABLE_REPEAT < self.REPEATS:
            self.LINE_REPEAT = 1
            self.TABLE_LINE = 1
            self.TABLE_REPEAT += 1
        else:
            return self.do_disable()
        return self.do_check_trigger(ts)

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Loading a table trumps everything
        if changes.get(b.TABLE_START, None) == 1:
            self.STATE = self.do_table_start()

        # Loading tables are special
        if self.STATE == LOAD_TABLE:
            if b.TABLE_DATA in changes:
                self.STATE = self.do_table_data(changes[b.TABLE_DATA])
            elif b.TABLE_LENGTH in changes:
                self.STATE = self.do_table_length(changes[b.TABLE_LENGTH])
        elif changes.get(b.ENABLE, None) == 0:
            # Otherwise check for disable
            self.STATE = self.do_disable()

        # If waiting for enable
        if self.STATE == WAIT_ENABLE:
            if changes.get(b.ENABLE, None) == 1:
                self.STATE = self.do_enable()

        if self.STATE == WAIT_TRIGGER:
            # If waiting for triggers check them here
            self.STATE = self.do_check_trigger(ts)
        elif self.STATE == PHASE1:
            # If doing phase 1, check if time has expired
            if ts == self.next_ts:
                self.STATE = self.do_phase_2(ts)
        elif self.STATE == PHASE2:
            # If doing phase 2, check if time has expired
            if ts == self.next_ts:
                self.STATE = self.do_next_line(ts)

        return self.next_ts
