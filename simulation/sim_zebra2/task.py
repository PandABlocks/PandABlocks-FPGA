class Task(object):
    def __init__(self):
        self.make_queue()
        self.setup_event_loop()
        
    def make_queue(self):
        from Queue import Queue, Empty
        self.q = Queue()
        self._EmptyException = Empty
        
    def post(self, event):
        self.q.put(event)
        
    def get_next_event(self, timeout=None):
        try:
            result = self.q.get(timeout=timeout)
        except self._EmptyException:
            return None
        else:
            return result
    
    def start_event_loop(self):
        from threading import Thread
        self.t = Thread(target=self.event_loop)
        self.t.daemon = True
        self.t.start()
    
    def setup_event_loop(self):
        pass
    
    def event_loop(self):
        while True:
            self.handle_events()

