# Extension module to support FMC ADC427
from .fmc_acq427 import Extension
from i2c import smbus2

# The mapping of GPIO bits is as follows:
#   0.1:0   ADC A4 gain
#   0.3:2   ADC A3 gain
#   0.5:4   ADC A2 gain
#   0.7:6   ADC A1 gain
#   1.1:0   ADC B4 gain
#   1.3:2   ADC B3 gain
#   1.5:4   ADC B2 gain
#   1.7:6   ADC B1 gain
#   2.0     CLK_DIR (unused)
#   2.1     TRIG_DIR (unused)
#   2.2     DAC_RIBBON - 0 if DAC output fitted         (input)
#   2.3     ADC_B_RIBBON - 0 if ADC B output fitted     (input)
#   2.4     DAC 2 output range
#   2.5     DAC 1 output range
#   2.6     DAC 4 output range
#   2.7     DAC 3 output range
lookup_bit_map = {
    # All the write values are triple: (byte, offset, width)
    'adc1_gain' : (0, 6, 2),
    'adc2_gain' : (0, 4, 2),
    'adc3_gain' : (0, 2, 2),
    'adc4_gain' : (0, 0, 2),
    'adc5_gain' : (1, 6, 2),
    'adc6_gain' : (1, 4, 2),
    'adc7_gain' : (1, 2, 2),
    'adc8_gain' : (1, 0, 2),
    'dac1_gain' : (2, 5, 1),
    'dac2_gain' : (2, 4, 1),
    'dac3_gain' : (2, 7, 1),
    'dac4_gain' : (2, 6, 1),
    # The two read values are a pair: (byte, offset)
    'dac_ribbon' : (2, 2),
    'adc_ribbon' : (2, 3),
}


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
        mask = ((1 << width) - 1) << offset
        value = (value << offset) & mask
        self.outputs[byte_ix] = (self.outputs[byte_ix] & ~mask) | value
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


# We need a single GPIO controller shared between the ADC and DAC extensions.
gpio_helper = GPIO_Helper()


class Extension:
    def __init__(self, count):
        pass

    def parse_read(self, request):
        return BitReader(gpio_helper, lookup_bit_map[request])

    def parse_write(self, request):
        return BitsWriter(gpio_helper, lookup_bit_map[request])
