# Extension module to support FMC ADC427
try:
    from i2c import smbus2
    import struct
except ImportError:
    from pandai2c import smbus2

# The absolute address on the EEPROM based on the documentation
#   0xCD Magic number 0
#   0xD1 Magic number 1
#   0xD5 RNG #0 CH #0 Gain
#   0xD9 RNG #0 CH #0 Offset
#   0xDD RNG #0 CH #1 Gain
#   0xE1 RNG #0 CH #1 Offset
#   0xE5 RNG #0 CH #2 Gain
#   0xE9 RNG #0 CH #2 Offset
#   0xED RNG #0 CH #3 Gain
#   0xF1 RNG #0 CH #3 Offset
#   0xF5 RNG #1 CH #0 Gain
#   0xF9 RNG #1 CH #0 Offset
#   0xFD RNG #1 CH #1 Gain
#   0x101 RNG #1 CH #1 Offset
#   0x105 RNG #1 CH #2 Gain
#   0x109 RNG #1 CH #2 Offset
#   0x10D RNG #1 CH #3 Gain
#   0x111 RNG #1 CH #3 Offset
# ...
#   0x11D Magic number 3
#   0x121 RNG #0 CH #0 User Offset
#   0x125 RNG #1 CH #0 User Offset
#   0x129 RNG #0 CH #1 User Offset
#   0x12D RNG #1 CH #1 User Offset
#   0x131 RNG #0 CH #2 User Offset
#   0x135 RNG #1 CH #2 User Offset
#   0x139 RNG #0 CH #3 User Offset
#   0x13D RNG #1 CH #3 User Offset


lookup_write_bit_map = {
    'magic3' : 0x11D,
    'rng0chn0useroffset' : 0x121,
    'rng1chn0useroffset' : 0x125,
    'rng0chn1useroffset' : 0x129,
    'rng1chn1useroffset' : 0x12D,
    'rng0chn2useroffset' : 0x131,
    'rng1chn2useroffset' : 0x135,
    'rng0chn3useroffset' : 0x139,
    'rng1chn3useroffset' : 0x13D,
}

lookup_read_bit_map = {
    'chn0_gain' : 0xD5,
    'chn0_offset' : 0xD9,
    'chn1_gain' : 0xDD,
    'chn1_offset' : 0xE1,
    'chn2_gain' : 0xE5,
    'chn2_offset' : 0xE9,
    'chn3_gain' : 0xED,
    'chn3_offset' : 0xF1
}


class GPIO_Helper:
    def __init__(self):
        self.bus = smbus2.SMBus(0)

    def read_input_bits(self, address):
        return self.bus.read_i2c_block_data(0x50, address, 4)

    def write_output_bits(self, bits):
        self.bus.write_i2c_block_data(0x50, 0x84, bits)

    def read_bit(self, address):
        contents = self.read_input_bits(address)
        return struct.unpack('<f', bytes(contents))[0]
    
    def write_bits(self, value, byte_ix, offset, width):
        mask = ((1 << width) - 1) << offset
        shift_value = (value << offset) & mask
        self.outputs[byte_ix] = (self.outputs[byte_ix] & ~mask) | shift_value
        self.write_output_bits(self.outputs)

    def write_adc_gain(self, value, *args):
        self.write_bits(value, *args)
        return (value,)

    def write_dac_gain(self, *args):
        # dac_gains do not write to a register and should not return a value
        self.write_bits(*args)


# We need a single GPIO controller shared between the ADC and DAC extensions.
gpio_helper = GPIO_Helper()


class Extension:
    def __init__(self, count):
        pass

    def parse_read(self, request):
        address = lookup_read_bit_map[request]
        return lambda _: gpio_helper.read_bit(address)

    def parse_write(self, request):
        action, offsets = lookup_write_bit_map[request]
        action = getattr(gpio_helper, action)
        return lambda _, value: action(value, *offsets)
