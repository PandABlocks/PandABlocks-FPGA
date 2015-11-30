# Implementation of hardware simulation


# Must return an integer
def do_read_data(block, num, reg):
    print 'do_read_data', block, num, reg
    return 0x55555555


def do_write_config(block, num, reg, value):
    print 'do_write_config', block, num, reg, repr(value)


def do_write_short_table(block, number, reg, data):
    print 'do_write_short_table', block, number, reg, len(data)


def do_write_long_table(block, number, data):
    print 'do_write_long_table', block, number, len(data)


# Must return two boolean arrays, each 128 entries long.  The first array is the
# current bit readback, the second is set if the bit value has changed since the
# last reading.
def do_read_bits():
    print 'do_read_bits'
    return 128*[1], 128*[1]


# Must return a 32-entry array of ints and a 32-bit boolean array.
def do_read_positions():
    print 'do_read_positions'
    return 32*[0], 32*[1]


# Sets bit capture mask
def set_bit_capture(mask):
    print 'set_bit_capture %x' % mask


# Sets position capture mask
def set_pos_capture(mask):
    print 'set_pos_capture %08x' % mask
