from .block import Block
from .event import Event


class Seq(Block):
    def __init__(self, num):
        super(Seq, self).__init__(num)
        self.active = 0
        self.frame = []
        self.table = []
        self.start_ts = 0
        self.table_len = 0
        self.cur_frame = 0
        self.table_repeats = 0
        self.input_use = 0
        self.input_conditions = 0
        self.phase1_outputs = 0
        self.phase2_outputs = 0
        self.prescale = 1

    def do_start(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 1
        self.cur_frame = 1
        self.start_ts = event.ts
        self.frame_start = event.ts
        self.CUR_FRAME = self.cur_frame

    def do_stop(self, next_event, event):
        next_event.bit[self.ACTIVE] = self.active = 0
        self.cur_frame = 0
        self.CUR_FRAME = self.cur_frame #not sure if this is needed here, only if stopping restarts the sequencer..

    def process_inputs(self, next_event, event):
        if self.active:
            # only process the inputs when the state is active
            pass

    def get_cur_frame(self, next_event, event):
        table_addr_offset = 4*(self.cur_frame - 1)
        #if in active state, the current frame depends on the length of the frame (phase1 + phase2) and the number of repeats of that frame
        if self.active and (event.ts - self.frame_start) > (self.table[2+table_addr_offset] * self.prescale + self.table[3+table_addr_offset] * self.prescale) * (self.table[0+table_addr_offset] + 1):
            self.cur_frame+=1
            self.frame_start = event.ts
            self.CUR_FRAME = self.cur_frame
        #TODO: make sure to handle what happens when all the frames are finished

    def do_table_write(self, next_event, event):
        self.table.append(self.TABLE_DATA)
        self.table_len = divmod(len(self.table),4)[0]

        #get the required data from the table
        # if self.word_count == 2:
        #     self.input_use = '{0:X}'.format(self.TABLE_DATA)[0]
        #     self.input_conditions = '{0:X}'.format(self.TABLE_DATA)[1]
        #     self.phase1_outputs = '{0:X}'.format(self.TABLE_DATA)[2:4]
        #     self.phase2_outputs = '{0:X}'.format(self.TABLE_DATA)[4:6]
            # print "IU: " + str(self.input_use) + ", IC: " + str(self.input_conditions) + ", P1o: " + str(self.phase1_outputs) + ", p2o: " + str(self.phase2_outputs)


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
            for name, value in event.bit.items():
                if name in [self.INPA, self.INPB, self.INPC, self.INPD] and value:
                    self.process_inputs(next_event, event)
                if name == self.GATE and value:
                    self.do_start(next_event, event)
                elif name == self.GATE and not value:
                    self.do_stop(next_event, event)

        # return any changes and next ts
        return next_event
