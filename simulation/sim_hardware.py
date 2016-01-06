# Implementation of hardware simulation


class Controller(object):
    def start(self):
        pass

    # Must return an integer
    def do_read_data(self, block, num, reg):
        return 0


    def do_write_config(self, block, num, reg, value):
        pass


    def do_write_table(self, block, number, reg, data):
        pass


    # Must return two boolean arrays, each 128 entries long.  The first array is
    # the current bit readback, the second is set if the bit value has changed
    # since the last reading.
    def do_read_bits(self):
        return 128*[False], 128*[False]


    # Must return a 32-entry array of ints and a 32-bit boolean array.
    def do_read_positions(self):
        return 32*[0], 32*[False]


    # Sets bit capture mask
    def set_bit_capture(self, mask):
        pass


    # Sets position capture mask
    def set_pos_capture(self, capture_mask, framed_mask, extended_mask):
        pass

