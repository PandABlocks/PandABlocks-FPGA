from .block import Block
from .event import Event


class Seq(Block):
    def __init__(self, num):
        super(Seq, self).__init__(num)
        self.inputs = {'A':0, 'B':0, 'C':0, 'D':0}
        self.active = 0
        self.frame = []
        self.table = []
        self.start_ts = 0
        self.frame_start = 0
        self.table_len = 0
        self.cur_frame = 0
        self.cur_phase = 1
        self.table_repeats = 0
        self.input_use = 0
        self.input_conditions = 0
        self.phase1_outputs = 0
        self.phase2_outputs = 0
        self.prescale = 1
        self.total_length_ts = 0
        self.frame_word_count = 0
        self.frame_ok = False # used to make sure a whole frame is written to the table before doing anything *not sure if this needs to happen each time we start writing a frame..
        self.phase1_times = []
        self.phase2_times = []

    def do_start(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 1
        self.cur_frame = 1
        self.start_ts = event.ts
        self.frame_start = event.ts
        self.CUR_FRAME = self.cur_frame

    def do_stop(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 0
        self.cur_frame = 0
        self.CUR_FRAME = self.cur_frame

    def process_inputs(self, next_event, event):
        #todo: refactor this method
        if self.active and self.frame_ok:
            #record inputs
            input_map = {self.INPA:'A', self.INPB:'B', self.INPC:'C', self.INPD:'D'}
            for name, val in event.bit.items():
                self.inputs[input_map[name]] = val

            #get input array
            inputarray = []
            for name, value in self.inputs.iteritems():
                inputarray.append(value)
            inputint = int(''.join(map(str,inputarray)),2)


            # if inputs and input bitmask == input conditions, outputs = phase outputs
            table_addr_offset = 4*(self.cur_frame - 1)
            inputbitmask = int('{0:X}'.format(self.table[1+table_addr_offset])[0], 16) #convert table value back to hex, get first value (4 bits) and convert the string to an int
            inputconditions = int('{0:X}'.format(self.table[1+table_addr_offset])[1], 16)
            phase1outputs = format(int('{0:X}'.format(self.table[1+table_addr_offset])[2:4],16),'06b') #convert table value back to hex, get output bits (6 bits), convert back to integer and then format to a binary string
            phase2outputs = format(int('{0:X}'.format(self.table[1+table_addr_offset])[4:6],16),'06b')
            if inputint & inputbitmask == inputconditions:
                if any((event.ts - self.start_ts) in i for i in self.phase1_times):
                    #TODO: make sure order is correct here
                    next_event.bit[self.OUTA] = int(phase1outputs[5])
                    next_event.bit[self.OUTB] = int(phase1outputs[4])
                    next_event.bit[self.OUTC] = int(phase1outputs[3])
                    next_event.bit[self.OUTD] = int(phase1outputs[2])
                    next_event.bit[self.OUTE] = int(phase1outputs[1])
                    next_event.bit[self.OUTF] = int(phase1outputs[0])
                elif any((event.ts - self.start_ts) in i for i in self.phase2_times):
                    #TODO: make sure order is correct here
                    next_event.bit[self.OUTA] = int(phase2outputs[5])
                    next_event.bit[self.OUTB] = int(phase2outputs[4])
                    next_event.bit[self.OUTC] = int(phase2outputs[3])
                    next_event.bit[self.OUTD] = int(phase2outputs[2])
                    next_event.bit[self.OUTE] = int(phase2outputs[1])
                    next_event.bit[self.OUTF] = int(phase2outputs[0])


    def get_cur_frame(self, next_event, event):
        table_addr_offset = 4*(self.cur_frame - 1)
        #if in active state, the current frame depends on the length of the frame (phase1 + phase2) and the number of repeats of that frame
        if self.active and (event.ts - self.frame_start) > ((self.table[2+table_addr_offset] + self.table[3+table_addr_offset]) * self.prescale) * (self.table[0+table_addr_offset] + 1):
            self.cur_frame+=1
            self.frame_start = event.ts
            self.CUR_FRAME = self.cur_frame
        elif self.active and (event.ts - self.frame_start) > self.total_length_ts:
            next_event.bit[self.ACTIVE] = self.active = 0
            #TODO: make sure to handle properly what happens when all the frames are finished

    def do_table_write(self, next_event, event):
        self.table.append(self.TABLE_DATA)
        self.table_len = divmod(len(self.table),4)[0]

        #get the total length of the table in terms of clock ticks
        self.frame_word_count += 1
        if self.frame_word_count == 4:
            self.frame_word_count = 0
            self.get_table_length_ts()
            self.frame_ok = True

    def get_table_length_ts(self):
        table_addr_offset = 4*(self.cur_frame - 1)
        repeats = int('{0:X}'.format(self.table[0 + table_addr_offset]),16)
        phase1len = int('{0:X}'.format(self.table[2 + table_addr_offset]),16)* self.prescale
        phase2len = int('{0:X}'.format(self.table[3 + table_addr_offset]),16)* self.prescale

        #get the phase time indexes so we can check which phase we are in later

        framelength = (phase1len+phase2len)
        for y in range(repeats+1):
            phase1times = [x + self.total_length_ts for x in range(y*framelength, phase1len+framelength*y)]
            phase2times = [x + self.total_length_ts for x in range(y*framelength+phase1len, framelength*(y+1))]
            self.phase1_times.append(phase1times)
            self.phase2_times.append(phase2times)
            # phase1times.append(range(self.total_length_ts)[0:phase1len*self.prescale])

        self.total_length_ts += ((phase1len + phase2len)* self.prescale) * repeats

    def on_event(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        #get the current frame
        self.get_cur_frame(next_event, event)
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
                    self.table = []
                    self.table_len = 0
                elif name == "TABLE_CYCLE":
                    self.table_repeats = self.TABLE_CYCLE
                elif name == "PRESCALE":
                    self.prescale = self.PRESCALE
        # if we got an input on a rising edge, then process it
        elif event.bit:
            if any(x in event.bit for x in [self.INPA, self.INPB, self.INPC, self.INPD]):
                    self.process_inputs(next_event, event)
            for name, value in event.bit.items():
                if name == self.GATE and value:
                    self.do_start(next_event, event)
                elif name == self.GATE and not value:
                    self.do_stop(next_event, event)

        # return any changes and next ts
        return next_event
