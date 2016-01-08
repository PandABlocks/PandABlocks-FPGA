import numpy

from .block import Block
from .event import Event
from collections import deque, OrderedDict

class Seq(Block):
    def __init__(self, num):
        super(Seq, self).__init__(num)
        self.inputs = {'A':0, 'B':0, 'C':0, 'D':0}
        self.table_data = {'repeats':0, 'inputBitMask': 0, 'inputConditions':0, 'phase1Outputs':0, 'phase2Outputs':0, 'phase1Len':0, 'phase2Len':0}
        self.active = 0
        self.table_len = 0
        self.table_write_addr = 0
        self.cur_frame = 0
        self.table_repeats = 0
        self.prescale = 1
        self.frame_word_count = 0
        self.frame_cycle = 0
        self.table_cycle = 0
        self.frame_ok = False
        self.phase2_queue = deque()
        self.frame_repeat_queue = deque()
        self.table_repeat_queue = deque()
        self.table = numpy.zeros(512*4, dtype=numpy.uint32)

    def do_start(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 1
        self.cur_frame = 1
        self.CUR_FRAME = self.cur_frame
        self.check_inputs(next_event, event)

    def do_stop(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 0
        self.cur_frame = 0
        self.frame_cycle = 0
        self.table_cycle = 0
        self.CUR_FRAME = self.cur_frame
        self.phase2_queue.clear()
        self.frame_repeat_queue.clear()
        self.table_repeat_queue.clear()
        self.CUR_TCYCLE = self.table_cycle

    def process_inputs(self, next_event, event):
        #record inputs
        input_map = {self.INPA:'A', self.INPB:'B', self.INPC:'C', self.INPD:'D'}
        for name, val in event.bit.items():
            self.inputs[input_map[name]] = val
        if self.active and self.frame_ok:
            self.check_inputs(next_event, event)

    def check_inputs(self, next_event, event):
        inputint = self.get_input_interger()
        self.get_table_data()
        # if inputs & input bitmask == input conditions: outputs = phase outputs
        if inputint & self.table_data['inputBitMask'] == self.table_data['inputConditions']:
            self.set_outputs_phase1(next_event, event)

    def set_outputs_phase1(self, next_event, event):
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = (self.table_data['phase1Outputs'] & 1)
        next_event.bit[self.OUTB] = (self.table_data['phase1Outputs'] & 2) >> 1
        next_event.bit[self.OUTC] = (self.table_data['phase1Outputs'] & 4) >> 2
        next_event.bit[self.OUTD] = (self.table_data['phase1Outputs'] & 8) >> 3
        next_event.bit[self.OUTE] = (self.table_data['phase1Outputs'] & 16) >> 4
        next_event.bit[self.OUTF] = (self.table_data['phase1Outputs'] & 32) >> 5
        self.phase2_queue.append((event.ts + self.table_data['phase1Len']))

    def set_outputs_phase2(self, next_event, event):
        self.get_table_data()
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = (self.table_data['phase2Outputs'] & 1)
        next_event.bit[self.OUTB] = (self.table_data['phase2Outputs'] & 2) >> 1
        next_event.bit[self.OUTC] = (self.table_data['phase2Outputs'] & 4) >> 2
        next_event.bit[self.OUTD] = (self.table_data['phase2Outputs'] & 8) >> 3
        next_event.bit[self.OUTE] = (self.table_data['phase2Outputs'] & 16) >> 4
        next_event.bit[self.OUTF] = (self.table_data['phase2Outputs'] & 32) >> 5
        #if we have no more repeats, and there are more frames, the current frame should increase
        if self.cur_frame < self.table_len and self.frame_cycle == self.table_data['repeats']:
            self.cur_frame += 1
            self.frame_cycle = 0
            # self.CUR_FCYCLE = self.frame_cycle
        elif self.frame_cycle < self.table_data['repeats']:
            # self.frame_cycle += 1
            self.frame_repeat_queue.append((event.ts + self.table_data['phase2Len']))
        #if we are at the end of the table determine if we need to repeat it or not
        elif self.cur_frame == self.table_len:
            if self.table_cycle < self.table_repeats:
                self.table_cycle += 1
                self.cur_frame = 1
                self.frame_cycle = 0
                self.table_repeat_queue.append((event.ts + self.table_data['phase2Len']))
            elif self.table_cycle == self.table_repeats:
                next_event.bit[self.ACTIVE] = self.active = 0

    def get_input_interger(self):
        #get inputs as a single integer
        inputarray = []
        ordered_inputs = OrderedDict(reversed(sorted(self.inputs.items(), key=lambda t: t[0])))
        for name, value in ordered_inputs.iteritems():
            inputarray.append(value)
        return int(''.join(map(str,inputarray)),2)

    def get_cur_frame_cycle(self, next_event, event):
        self.CUR_FRAME = self.cur_frame
        self.CUR_FCYCLE = self.frame_cycle
        self.CUR_TCYCLE = self.table_cycle

    def do_table_write(self, next_event, event):
        self.frame_ok = False
        self.table[self.table_write_addr] = self.TABLE_DATA
        self.table_write_addr += 1
        #check that the whole frame is written
        self.frame_word_count += 1
        if self.frame_word_count == 4:
            self.frame_word_count = 0
            self.frame_ok = True 

    def do_table_reset(self):
        self.table_write_addr = 0
        pass

    def get_table_data(self):
        table_addr_offset = 4*(self.cur_frame - 1)
        self.table_data['repeats'] = self.table[0 + table_addr_offset]
        self.table_data['phase1Len'] = self.table[2 + table_addr_offset]* self.prescale
        self.table_data['phase2Len'] = self.table[3 + table_addr_offset]* self.prescale
        self.table_data['inputBitMask'] = (self.table[1+table_addr_offset] >>28) & 0xF
        self.table_data['inputConditions'] = (self.table[1+table_addr_offset] >> 24) & 0xF
        self.table_data['phase2Outputs'] = (self.table[1+table_addr_offset] >> 8) & 0x3F
        self.table_data['phase1Outputs'] = (self.table[1+table_addr_offset] >> 16) & 0x3F

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        self.get_cur_frame_cycle(next_event, event)
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "SOFT_GATE" and value:
                    self.do_start(next_event, event)
                if name == "SOFT_GATE" and not value:
                    self.do_stop(next_event, event)
                elif name == "TABLE_DATA":
                    self.do_table_write(next_event, event)
                elif name == "TABLE_RST":
                    self.do_table_reset()
                elif name == "TABLE_CYCLE":
                    self.table_repeats = value
                elif name == "PRESCALE":
                    self.prescale = value
                elif name == "TABLE_LENGTH":
                    self.table_len = value
                elif name == "TABLE":
                    self.table[:len(value)] = value
                    # write each value in value array to table
        # if we got an input on a rising edge, then process it
        elif event.bit:
            if any(x in event.bit for x in [self.INPA, self.INPB, self.INPC, self.INPD]):
                #if we are due to repeat, pop off the queue so we wait until the inputs are correct again
                if self.frame_repeat_queue:
                    self.frame_repeat_queue.popleft()
                self.process_inputs(next_event, event)
            for name, value in event.bit.items():
                if name == self.GATE and value:
                    self.do_start(next_event, event)
                elif name == self.GATE and not value:
                    self.do_stop(next_event, event)
        # if we have an event on one of our queues that is due, produce it
        if self.phase2_queue and self.phase2_queue[0] == event.ts:
            # generate output value
            self.phase2_queue.popleft()
            self.set_outputs_phase2(next_event, event)
        if self.frame_repeat_queue and self.frame_repeat_queue[0] == event.ts:
                self.frame_repeat_queue.popleft()
                self.set_outputs_phase1(next_event, event)
                self.frame_cycle += 1
                self.CUR_FCYCLE = self.frame_cycle
        if self.table_repeat_queue and self.table_repeat_queue[0] == event.ts:
                self.table_repeat_queue.popleft()
                self.set_outputs_phase1(next_event, event)
        # return any changes and next ts
        return next_event
