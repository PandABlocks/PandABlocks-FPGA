from .zebra2 import Zebra2


class Controller(object):

    def __init__(self):
        # start the controller task
        self.z = Zebra2()

    def start(self):
        self.z.start_event_loop()

    # Must return an integer
    def do_read_data(self, block, num, reg):
        block = self.z.blocks[(block, num)]
        name = block.regs[reg]
        value = getattr(block, name)
        return value

    def do_write_config(self, block, num, reg, value):
        self.z.post_wait((block, num, reg, value))

    def do_write_table(self, block, num, reg, data):
        self.z.post_wait((block, num, "TABLE", data))

    # Must return two boolean arrays, each 128 entries long.  The first array is
    # the current bit readback, the second is set if the bit value has changed
    # since the last reading.
    def do_read_bits(self):
        bus, changed_d = self.z.bit_bus[:], self.z.bit_changed
        self.z.bit_changed = {}
        changed = [0] * 128
        for i in changed_d:
            changed[i] = 1
        # TODO: this double counts, why?
        return bus, changed

    # Must return a 32-entry array of ints and a 32-bit boolean array.
    def do_read_positions(self):
        bus, changed_d = self.z.pos_bus[:], self.z.pos_changed
        self.z.pos_changed = {}
        changed = [0] * 32
        for i in changed_d:
            changed[i] = 1
        return bus, changed

    # Sets bit capture mask
    def set_bit_capture(self, mask):
        pass

    # Sets position capture mask
    def set_pos_capture(self, capture_mask, framed_mask, extended_mask):
        pass
