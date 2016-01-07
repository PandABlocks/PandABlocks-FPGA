from .block import Block
from .event import Event
from collections import deque

class Seq(Block):
    def __init__(self, num):
        super(Seq, self).__init__(num)
        self.inputs = {'A':0, 'B':0, 'C':0, 'D':0}
        self.table_data = {'repeats':0, 'inputBitMask': 0, 'inputConditions':0, 'phase1Outputs':0, 'phase2Outputs':0, 'phase1Len':0, 'phase2Len':0}
        self.active = 0
        self.table = []
        self.table_len = 0
        self.cur_frame = 0
        self.table_repeats = 0
        self.prescale = 1
        self.frame_word_count = 0
        self.frame_cycle = 0
        self.table_cycle = 0
        self.frame_ok = False
        self.phase2_queue = deque()
        self.repeat_queue = deque()

    def do_start(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 1
        self.cur_frame = 1
        self.CUR_FRAME = self.cur_frame
        self.check_inputs(next_event, event)

    def do_stop(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 0
        self.cur_frame = 0
        self.CUR_FRAME = self.cur_frame
        self.phase2_queue.clear()
        self.repeat_queue.clear()
        self.frame_cycle = 0
        self.table_cycle = 0

    def process_inputs(self, next_event, event):
        #process inputs only if in active state and a whole frame has been written to the table
        if self.active and self.frame_ok:
            #record inputs
            input_map = {self.INPA:'A', self.INPB:'B', self.INPC:'C', self.INPD:'D'}
            for name, val in event.bit.items():
                self.inputs[input_map[name]] = val
            self.check_inputs(next_event, event)

    def check_inputs(self, next_event, event):
        inputint = self.get_input_interger()
        self.get_table_data()
        # if inputs & input bitmask == input conditions, outputs = phase outputs
        if inputint & self.table_data['inputBitMask'] == self.table_data['inputConditions']:
            self.set_outputs_phase1(next_event, event)

    def set_outputs_phase1(self, next_event, event):
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = int(self.table_data['phase1outputs'][5])
        next_event.bit[self.OUTB] = int(self.table_data['phase1outputs'][4])
        next_event.bit[self.OUTC] = int(self.table_data['phase1outputs'][3])
        next_event.bit[self.OUTD] = int(self.table_data['phase1outputs'][2])
        next_event.bit[self.OUTE] = int(self.table_data['phase1outputs'][1])
        next_event.bit[self.OUTF] = int(self.table_data['phase1outputs'][0])
        self.phase2_queue.append((event.ts + self.table_data['phase1Len']))

    def set_outputs_phase2(self, next_event, event):
        self.get_table_data()
        #TODO: make sure order is correct here
        next_event.bit[self.OUTA] = int(self.table_data['phase2Outputs'][5])
        next_event.bit[self.OUTB] = int(self.table_data['phase2Outputs'][4])
        next_event.bit[self.OUTC] = int(self.table_data['phase2Outputs'][3])
        next_event.bit[self.OUTD] = int(self.table_data['phase2Outputs'][2])
        next_event.bit[self.OUTE] = int(self.table_data['phase2Outputs'][1])
        next_event.bit[self.OUTF] = int(self.table_data['phase2Outputs'][0])
        #if we have no more repeats, and there are more frames, the current frame should increase
        if self.cur_frame < self.table_len and self.frame_cycle == self.table_data['repeats']:
            self.cur_frame += 1
            self.frame_cycle = 0
        elif self.frame_cycle < self.table_data['repeats']:
            self.frame_cycle += 1
            self.repeat_queue.append((event.ts + self.table_data['phase2Len']))
        #if we are at the end of the table determine if we need to repeat it or not
        elif self.cur_frame == self.table_len:
            if self.table_cycle < self.table_repeats:
                self.table_cycle += 1
                self.cur_frame = 1
                self.frame_cycle = 0
                self.repeat_queue.append((event.ts + self.table_data['phase2Len']))
            elif self.table_cycle == self.table_repeats:
                next_event.bit[self.ACTIVE] = self.active = 0

    def get_input_interger(self):
        #get inputs as a single integer
        inputarray = []
        for name, value in self.inputs.iteritems():
            inputarray.append(value)
        return int(''.join(map(str,inputarray)),2)

    def get_cur_frame_cycle(self, next_event, event):
        self.CUR_FRAME = self.cur_frame
        self.CUR_FCYCLE = self.frame_cycle
        self.CUR_TCYCLE = self.table_cycle

    def do_table_write(self, next_event, event):
        self.frame_ok = False
        self.table.append(self.TABLE_DATA)
        #get the phase time indexes so we can check which phase we are in later and indicate that the whole frame is written
        self.frame_word_count += 1
        if self.frame_word_count == 4:
            # self.get_phase_time_indexes()
            self.frame_word_count = 0
            self.frame_ok = True #not sure if this should be if self.cur_frame ==0: self.frame_ok = True in order to only block on the first frame.
            #the current frame count starts only when we have a full frame written
            if self.cur_frame == 0: self.cur_frame = 1

    def do_table_reset(self):
        #this should make the table overwrite from the top
        pass

    def get_table_data(self):
        table_addr_offset = 4*(self.cur_frame - 1)
        self.table_data['repeats'] = int('{0:X}'.format(self.table[0 + table_addr_offset]),16)
        self.table_data['phase1Len'] = int('{0:X}'.format(self.table[2 + table_addr_offset]),16)* self.prescale
        self.table_data['phase2Len'] = int('{0:X}'.format(self.table[3 + table_addr_offset]),16)* self.prescale
        self.table_data['inputBitMask'] = int('{0:X}'.format(self.table[1+table_addr_offset])[0], 16) #convert table value back to hex, get first value (4 bits) and convert the string to an int
        self.table_data['inputConditions'] = int('{0:X}'.format(self.table[1+table_addr_offset])[1], 16)
        self.table_data['phase1outputs'] = format(int('{0:X}'.format(self.table[1+table_addr_offset])[2:4],16),'06b') #convert table value back to hex, get output bits (6 bits), convert back to integer and then format to a binary string
        self.table_data['phase2Outputs'] = format(int('{0:X}'.format(self.table[1+table_addr_offset])[4:6],16),'06b')

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

        # if we got an input on a rising edge, then process it
        elif event.bit:
            if any(x in event.bit for x in [self.INPA, self.INPB, self.INPC, self.INPD]):
                #if we are due to repeat, pop off the queue so we wait until the inputs are correct again
                if self.repeat_queue:
                    self.repeat_queue.popleft()
                self.process_inputs(next_event, event)
            for name, value in event.bit.items():
                if name == self.GATE and value:
                    self.do_start(next_event, event)
                elif name == self.GATE and not value:
                    self.do_stop(next_event, event)
        # if we have an pulse on our queue that is due, produce it
        if self.phase2_queue and self.phase2_queue[0] == event.ts:
            # generate output value
            self.phase2_queue.popleft()
            self.set_outputs_phase2(next_event, event)
        if self.repeat_queue and self.repeat_queue[0] == event.ts:
                self.repeat_queue.popleft()
                self.set_outputs_phase1(next_event, event)
        # return any changes and next ts
        return next_event
