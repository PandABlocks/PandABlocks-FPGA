# Implementation of hardware simulation


# Must return an integer
def do_read_data(block, num, reg):
    pass
    return 0


def do_write_config(block, num, reg, value):
    pass


def do_write_table(block, number, reg, data):
    pass


# Must return two boolean arrays, each 128 entries long.  The first array is the
# current bit readback, the second is set if the bit value has changed since the
# last reading.
def do_read_bits():
    return 128*[False], 128*[False]


# Must return a 32-entry array of ints and a 32-bit boolean array.
def do_read_positions():
    return 32*[0], 32*[False]


# Sets bit capture mask
def set_bit_capture(mask):
    pass


# Sets position capture mask
def set_pos_capture(mask):
    pass
