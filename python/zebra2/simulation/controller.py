import numpy
import threading
import time

from .zebra2 import Zebra2


class Controller(object):

    def __init__(self, config_dir):
        # start the controller task
        self.z = Zebra2(config_dir)
        self.capture = Capture()

        self.dummy_data = DummyData(self)

    def start(self):
        self.z.start_event_loop()
        self.dummy_data.start()


    # --------------------------------------------------------------------------
    # Interface to TCP server

    # Must return an integer
    def do_read_register(self, block_num, num, reg):
        try:
            block = self.z.blocks[(block_num, num)]
            name = block.regs[reg]
        except KeyError:
            # Unknown register, just ignore
            value = 0
        else:
            value = getattr(block, name)
        return value

    def do_write_register(self, block, num, reg, value):
        self.dummy_data.write_register(block == 31, reg, value)
        self.z.post_wait((block, num, reg, value))

    def do_write_table(self, block, num, reg, data):
        self.z.post_wait((block, num, "TABLE", data))

    def do_read_capture(self, max_length):
        return self.capture.read(max_length)


    # --------------------------------------------------------------------------
    # Data interface from hardware simulation

    # Call when arming data capture
    def start_capture_data(self):
        self.capture.write_start()

    # Call this periodically to generate data to be captured.
    def send_capture_data(self, data):
        self.capture.write(data)

    # Call at end of capture
    def end_capture_data(self):
        self.capture.write_end()


# Writing to this class is roughly equivalent to sending data to DMA on h/w
class Capture(object):
    max_buffer = 1 << 16

    def __init__(self):
        self.lock = threading.Lock()
        self.active = False
        self.buffer = numpy.empty(self.max_buffer, dtype = numpy.int32)
        self.length = 0

    def write_start(self):
        with self.lock:
            if self.active or self.length > 0:
                print 'Arming before previous capture complete'
            self.active = True
            self.length = 0

    def write(self, data):
        with self.lock:
            data_length = len(data)
            free_length = self.max_buffer - self.length
            if data_length > free_length:
                print 'Capture data overflow, %d words lost', \
                    len(data) - free_length
                data_length = free_length

            self.buffer[self.length:self.length + data_length] = \
                data[:data_length]
            self.length += data_length
            self.active = True

    def write_end(self):
        with self.lock:
            self.active = False

    def read(self, max_length):
        with self.lock:
            if self.length > 0:
                data_length = min(self.length, max_length)
                result = +self.buffer[:data_length]
                self.buffer[:self.length - data_length] = \
                    self.buffer[data_length:self.length]
                self.length -= data_length
                return result
            elif self.active:
                # Return empty array if there's no data but we're still active
                return self.buffer[:0]
            else:
                # Return None to indicate end of data capture stream
                return None


class DummyData(threading.Thread):
    def __init__(self, controller):
        super(DummyData, self).__init__()
        self.controller = controller
        self.armed = False

    def run(self):
        while True:
            time.sleep(1)
            if self.armed:
                for i in range(10):
                    if not self.armed:
                        break
                    self.controller.send_capture_data(
                        numpy.arange(1024, dtype=numpy.int32))
                    time.sleep(0.02)
                self.controller.end_capture_data()
                self.armed = False

    def write_register(self, cs, reg, value):
        if cs:
            if reg == 8:
                self.controller.start_capture_data()
                self.armed = True
            elif reg == 9:
                self.armed = False
