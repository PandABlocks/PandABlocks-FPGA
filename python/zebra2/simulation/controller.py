import numpy

from .zebra2 import Zebra2


class Controller(object):

    def __init__(self, config_dir):
        # start the controller task
        self.z = Zebra2(config_dir)

    def start(self):
        self.z.start_event_loop()

    # Must return an integer
    def do_read_register(self, block_num, num, reg):
        try:
            block = self.z.blocks[(block_num, num)]
            name = block.regs[reg]
        except KeyError:
            print 'Unknown register', block_num, num, reg
            value = 0
        else:
            value = getattr(block, name)
        return value

    def do_write_register(self, block, num, reg, value):
        self.z.post_wait((block, num, reg, value))

    def do_write_table(self, block, num, reg, data):
        self.z.post_wait((block, num, "TABLE", data))

    def do_read_capture(self, max_length):
        # Must return either None to signal end of capture stream (or no capture
        # stream available), or a 1-d numpy int32 array of at most max_length --
        # can be zero length to indicate no data available yet.
        return numpy.array([], dtype=numpy.int32)
