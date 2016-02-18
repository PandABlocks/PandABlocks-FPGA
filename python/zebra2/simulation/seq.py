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
        self.set_active_queue = deque()
        self.p2_queue = deque()
        self.next_frame_queue = deque()
        self.frpt_queue = deque()
        self.trpt_queue = deque()
        self.end_queue = deque()
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
        self.p2_queue.clear()
        self.frpt_queue.clear()
        self.trpt_queue.clear()
        self.next_frame_queue.clear()
        self.end_queue.clear()

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
        self.p2_queue.append((ts + self.params['p1Len']))
        #if we receive an input that matches criteria, and we are due to process
        #a repeat queue, clear the queue to prevent the outputs being set twice
        if self.frpt_queue and self.frpt_queue[0] == ts:
            self.frpt_queue.popleft()
        if self.trpt_queue and self.trpt_queue[0] == ts:
            self.trpt_queue.popleft()

    def process_phase2(self, ts):
        self.get_cur_frame_data()
        self.set_outputs('p2Out')
        #go to next frame
        if self.CUR_FRAME < self.TABLE_LENGTH\
            and self.CUR_FCYCLE == self.params['rpt']:
            self.next_frame_queue.append((ts + self.params['p2Len']))
        #handle repeating frames
        elif self.CUR_FCYCLE < self.params['rpt']:# or self.CUR_FCYCLE == 0:
            self.frpt_queue.append((ts + self.params['p2Len']))
        #handle repeating tables
        elif self.CUR_FRAME == self.TABLE_LENGTH:
            if self.CUR_TCYCLE < self.TABLE_CYCLE:# or self.CUR_TCYCLE == 0:
                self.trpt_queue.append((ts + self.params['p2Len']))
            elif self.CUR_TCYCLE == self.TABLE_CYCLE:
                self.end_queue.append(ts + self.params['p2Len'])

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
        self.TABLE_STROBES = self.table_strobes

    def do_table_reset(self):
        self.twrite_addr = 0
        self.ACTIVE = 0
        self.set_outputs('zero')
        self.reset_state()

    def do_table_write_finished(self):
        if self.GATE:
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

        if b.SOFT_GATE in changes or b.GATE in changes:
            if self.SOFT_GATE or self.GATE:
                self.do_start(ts)
            else:
                self.do_stop()
        elif b.TABLE_DATA in changes:
            self.do_table_write()
        elif b.TABLE_START in changes:
            self.reset_state()
            self.do_table_reset()
        elif b.TABLE_LENGTH in changes:
            self.set_active_queue.append(ts+1)

        input_bits = [b.INPA, b.INPB, b.INPC, b.INPD]
        if any(x in changes for x in input_bits):
            #if we are due to repeat, pop off the queue so we wait until
            #the inputs are correct again
            if self.frpt_queue:
                self.frpt_queue.popleft()
            self.process_inputs(ts)

        #if we are due to set registers after a TABLE_LENGTH write
        if self.set_active_queue and self.set_active_queue[0] <= ts:
            self.set_active_queue.popleft()
            self.do_table_write_finished()
        #set phase 2 outputs when the phase 1 time has finished
        if self.p2_queue and self.p2_queue[0] == ts:
            self.p2_queue.popleft()
            self.process_phase2(ts)
        #handle the frame repeat
        if self.frpt_queue and self.frpt_queue[0] == ts:
            self.CUR_FCYCLE += 1
            self.frpt_queue.popleft()
            self.process_inputs(ts)
        #handle the table repeat
        if self.trpt_queue and self.trpt_queue[0] == ts:
            self.CUR_TCYCLE += 1
            self.CUR_FRAME  = 1
            self.CUR_FCYCLE = 1
            self.trpt_queue.popleft()
            self.process_inputs(ts)
        #handle the next frame
        if self.next_frame_queue and self.next_frame_queue[0] <= ts:
            self.CUR_FRAME += 1
            self.CUR_FCYCLE = 1
            self.next_frame_queue.popleft()
            self.process_inputs(ts)
        #handle the end of the sequence
        if self.end_queue and self.end_queue[0] == ts:
            self.end_queue.popleft()
            self.set_outputs('zero')
            self.ACTIVE = 0
