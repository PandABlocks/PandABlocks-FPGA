from .block import Block
from .event import Event

class Seq(Block):

    def do_start(self, next_event, event):
        pass

    def do_stop(self, next_event, event):
        pass

    def process_inputs(self, next_event, event):
        pass

    def do_table_reset(self, next_event, event):
        pass

    def do_table_write(self, next_event, event):
        pass


    def on_event_hidden(self, event):
        """Handle register, bit and pos changes at a particular timestamps,
        then generate output events and return when we next need to be called"""
        next_event = Event()
        # if we got register changes, handle those
        if event.reg:
            for name, value in event.reg.items():
                setattr(self, name, value)
                if name == "TABLE_CYCLE" and value:
                    self.do_table_reset(next_event, event)
                elif name == "TABLE" and value:
                    self.do_table_write(next_event, event)
        # if we got an input on a rising edge, then process it
        elif event.bit:
            for name, value in event.bit.items():
                if name in [self.INPA, self.INPB, self.INPC, self.INPD] \
                        and value:
                    self.process_inputs(next_event, event)
                if name == "GATE" and value:
                    self.do_start(next_event,event)
                elif name =="GATE" and not value:
                    self.do_stop(next_event,event)

        # return any changes and next ts
        return next_event
