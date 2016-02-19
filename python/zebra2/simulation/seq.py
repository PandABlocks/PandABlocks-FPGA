import numpy

from .block import Block
from collections import deque, OrderedDict

class Seq(Block):
    def __init__(self):
        # super(Seq, self).__init__(num)
        self.params = {'rpt':0,
                        'inMask': 0,
                        'inCond':0,
                        'p1Out':0,
                        'p2Out':0,
                        'p1Len':0,
                        'p2Len':0
                       }
        self.twrite_addr = 0
        self.fword_count = 0
        self.table_strobes = 0
        self.frame_ok = False
        self.queue = deque()
        self.table = numpy.zeros(shape=(512,4), dtype=numpy.uint32)

    def do_start(self, ts):
        self.ACTIVE = 1
        self.CUR_FRAME = 1
        self.CUR_FCYCLE = 1
        self.CUR_TCYCLE = 1
        self.process_inputs(ts)

    def do_stop(self):
        self.ACTIVE = 0
        self.set_outputs('zero')
        self.reset_state()

    def reset_state(self):
        self.CUR_FRAME = 0
        self.CUR_FCYCLE = 0
        self.CUR_TCYCLE = 0
        self.queue.clear()

    def process_inputs(self, ts):
        if self.ACTIVE and self.frame_ok:
            self.get_cur_frame_data()
            incheck = self.params['inMask'] & self.params['inCond']
            if (self.INPA & (self.params['inMask'] & 1) == incheck & 1)\
                and (self.INPB & ((self.params['inMask'] & 2) >> 1)
                         == (incheck & 2) >> 1)\
                and (self.INPC & ((self.params['inMask'] & 4) >> 2)
                         == (incheck & 4) >> 2)\
                and (self.INPD & ((self.params['inMask'] & 8) >> 3)
                         == (incheck & 8) >> 3):
                self.process_phase1(ts)

    def process_phase1(self, ts):
        self.set_outputs('p1Out')
        self.queue.append((ts + self.params['p1Len'], "phase2"))
        #if we receive an input that matches criteria, and we are due to process
        #a repeat queue, clear the queue to prevent the outputs being set twice
        if self.queue and self.queue[0][1] == "frpt":
            self.queue.popleft()
        if self.queue and self.queue[0][1] == "trpt":
            self.queue.popleft()

    def process_phase2(self, ts):
        self.get_cur_frame_data()
        self.set_outputs('p2Out')
        #handle repeating frames
        if self.CUR_FCYCLE < self.params['rpt']:# or self.CUR_FCYCLE == 0:
            self.queue.append((ts + self.params['p2Len'], "frpt"))
        #go to next frame
        elif self.CUR_FRAME < self.TABLE_LENGTH / 4 \
            and self.CUR_FCYCLE == self.params['rpt']:
            self.queue.append((ts + self.params['p2Len'], "next_frame"))
        #handle repeating tables
        elif self.CUR_FRAME == self.TABLE_LENGTH / 4:
            if self.CUR_TCYCLE < self.TABLE_CYCLE:# or self.CUR_TCYCLE == 0:
                self.queue.append((ts + self.params['p2Len'], "trpt"))
            elif self.CUR_TCYCLE == self.TABLE_CYCLE:
                self.queue.append((ts + self.params['p2Len'], "end"))

    def set_outputs(self, phse):
        #TODO: make sure order is correct here
        self.OUTA = (self.params[phse] & 1) if phse in self.params else 0
        self.OUTB = (self.params[phse] & 2) >> 1 if phse in self.params else 0
        self.OUTC = (self.params[phse] & 4) >> 2 if phse in self.params else 0
        self.OUTD = (self.params[phse] & 8) >> 3 if phse in self.params else 0
        self.OUTE = (self.params[phse] & 16) >> 4 if phse in self.params else 0
        self.OUTF = (self.params[phse] & 32) >> 5 if phse in self.params else 0

    def do_table_write(self):
        self.frame_ok = False
        self.table[self.twrite_addr][self.fword_count] = self.TABLE_DATA
        self.fword_count += 1
        self.table_strobes += 1
        #check that the whole frame is written
        if self.fword_count == 4:
            self.fword_count = 0
            self.frame_ok = True
            self.twrite_addr += 1

    def do_table_reset(self):
        self.twrite_addr = 0
        self.ACTIVE = 0
        self.set_outputs('zero')
        self.reset_state()

    def do_table_write_finished(self):
        if self.ENABLE:
            self.ACTIVE = 1
            self.CUR_FRAME = 1
            self.CUR_FCYCLE = 1
            self.CUR_TCYCLE = 1
        self.table_strobes = 0

    def get_cur_frame_data(self):
        #make the data more easily managable
        self.params['rpt'] = self.table[self.CUR_FRAME-1][0]
        self.params['p1Len'] = self.table[self.CUR_FRAME-1][2] * self.PRESCALE
        self.params['p2Len'] = self.table[self.CUR_FRAME-1][3] * self.PRESCALE
        self.params['inMask'] = (self.table[self.CUR_FRAME-1][1] >> 28) & 0xF
        self.params['inCond'] = (self.table[self.CUR_FRAME-1][1] >> 24) & 0xF
        self.params['p2Out'] = (self.table[self.CUR_FRAME-1][1] >> 8) & 0x3F
        self.params['p1Out'] = (self.table[self.CUR_FRAME-1][1] >> 16) & 0x3F

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        if b.ENABLE in changes:
            if self.ENABLE:
                self.do_start(ts)
            else:
                self.do_stop()
        elif b.TABLE_DATA in changes:
            self.do_table_write()
        elif b.TABLE_START in changes:
            self.reset_state()
            self.do_table_reset()
        elif b.TABLE_LENGTH in changes:
            self.queue.append((ts+1, "active"))

        input_bits = [b.INPA, b.INPB, b.INPC, b.INPD]
        if any(x in changes for x in input_bits):
            #if we are due to repeat, pop off the queue so we wait until
            #the inputs are correct again
            if self.queue and self.queue[0][1] == "frpt":
                self.queue.popleft()
            self.process_inputs(ts)

        #set phase 2 outputs when the phase 1 time has finished
        if self.queue and self.queue[0][0] == ts:
            if self.queue[0][1] == "phase2":
                self.queue.popleft()
                self.process_phase2(ts)
            elif self.queue[0][1] == "frpt":
                self.CUR_FCYCLE += 1
                self.queue.popleft()
                self.process_inputs(ts)
            elif self.queue[0][1] == "trpt":
                self.CUR_TCYCLE += 1
                self.CUR_FRAME  = 1
                self.CUR_FCYCLE = 1
                self.queue.popleft()
                self.process_inputs(ts)
            elif self.queue[0][1] == "end":
                self.queue.popleft()
                self.set_outputs('zero')
                self.ACTIVE = 0
        if self.queue and self.queue[0][0] <= ts:
            if self.queue[0][1] == "next_frame":
                self.CUR_FRAME += 1
                self.CUR_FCYCLE = 1
                self.queue.popleft()
                self.process_inputs(ts)
             #if we are due to set registers after a TABLE_LENGTH write
            elif self.queue[0][1] == "active":
                self.queue.popleft()
                self.do_table_write_finished()

