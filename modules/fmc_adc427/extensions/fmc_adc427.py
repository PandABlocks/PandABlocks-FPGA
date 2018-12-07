# Extension module to support FMC ADC427

# The mapping of GPIO bits is as follows:
#   0.1:0   ADC A1 gain
#   0.3:2   ADC A2 gain
#   0.5:4   ADC A3 gain
#   0.7:6   ADC A4 gain
#   1.1:0   ADC B1 gain
#   1.3:2   ADC B2 gain
#   1.5:4   ADC B3 gain
#   1.7:6   ADC B4 gain
#   2.0     CLK_DIR (unused)
#   2.1     TRIG_DIR (unused)
#   2.2     DAC_RIBBON - 0 if DAC output fitted         (input)
#   2.3     ADC_B_RIBBON - 0 if ADC B output fitted     (input)
#   2.4     DAC 3 output range
#   2.5     DAC 4 output range
#   2.6     DAC 1 output range
#   2.7     DAC 2 output range

from i2c import smbus2


class GPIO_Helper:
    def __init__(self):
        self.bus = smbus2.SMBus(0)
        self.outputs = [0, 0, 0]
        self.write_config_bits([0x00, 0x00, 0x0c])

    def read_input_bits(self):
        return self.bus.read_i2c_block_data(0x22, 0x80, 3)

    def write_config_bits(self, bits):
        self.bus.write_i2c_block_data(0x22, 0x8c, bits)

    def write_output_bits(self, bits):
        self.bus.write_i2c_block_data(0x22, 0x84, bits)

    def read_bit(self, (byte_ix, offset)):
        bits = self.read_input_bits()
        return bool(bits[byte_ix] & (1 << offset))

    def write_bits(self, (byte_ix, offset, width), value):
        mask = (1 << width) - 1
        value = value & mask
        self.outputs[byte_ix] = \
            (self.outputs[byte_ix] & ~mask) | (value << offset)
        self.write_output_bits(self.outputs)

class BitReader:
    def __init__(self, gpio, offset):
        self.gpio = gpio
        self.offset = offset

    def read(self, number):
        return self.gpio.read_bit(self.offset)

class BitsWriter:
    def __init__(self, gpio, offset):
        self.gpio = gpio
        self.offset = offset

    def write(self, number, value):
        self.gpio.write_bits(self.offset, value)


# Parses byte.bit into a pair of values.
def parse_bit(s):
    byte, offset = map(int, s.split('.'))
    return (byte, offset)

# Parses byte.left:right into a triple (byte, offset, length)
def parse_bits(s):
    byte, lr = s.split('.')
    byte = int(byte)
    left, right = map(int, lr.split(':'))
    return (byte, right, left - right + 1)


class Extension:
    def __init__(self, count):
        self.gpio = GPIO_Helper()

    def parse_read(self, request):
        return BitReader(self.gpio, parse_bit(request))

    def parse_write(self, request):
        return BitsWriter(self.gpio, parse_bits(request))
