# Extension module to support FMC PICO-1M4

from pandai2c import eeprom, smbus2

import struct

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
    'chn0' : [0xD5,0xD9],
    'chn1' : [0xDD,0xE1],
    'chn2' : [0xE5, 0xE9],
    'chn3' : [0xED,0xF1]
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
        # we cache the memory, it is not expected to change
        self.memory = eeprom.read_address(length=0x140)

    def read_dword(self, address):
        assert address + 4 <= len(self.memory)
        return self.memory[address:address+4]

    def read_bit(self, address):
        contents = self.read_dword(address)
        return struct.unpack('<f', bytes(contents))[0]
    

# We need a single GPIO controller shared between the ADC and DAC extensions.
gpio_helper = GPIO_Helper()


class Extension:
    def __init__(self, count):
        pass

    def parse_read(self, request):
        gain, offset = lookup_read_bit_map[request]
        return lambda x,value: (x+gpio_helper.read_bit(gain)) + gpio_helper.read_bit(offset)