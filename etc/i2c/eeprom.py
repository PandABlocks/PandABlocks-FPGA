# Helper for reading EEPROM
import errno

import numpy

from . import smbus2, parse_ipmi


def read_bytes(bus, device, length = 32):
    read = smbus2.i2c_msg.read(device, length)
    bus.i2c_rdwr(read)
    return list(read)


# Detect a 16-bit address device using only safe 8-bit address commands
#
# The issue here is that we don't know whether we have a 24c02 or a 24c64
# compatible device in the FMC EEPROM -- and these two devices have incompatible
# access methods.  In particular, the 24c64 needs a two byte read address to be
# written to it, whereas the 24c02 interprets a two byte write as writing a byte
# to the EEPROM.
# Here we attempt to read the IPMI header twice in 8-bit mode.
# If we get the header successfully twice then 8-bit addressing worked.
# If not we assume the device is 16-bit addressed 
# NOTE: this fails for an 8-bit device which doesn't contain valid data

def detect_16bit(device = 0x50):
    first_read  = read_8bit_address(device, length = 8)
    second_read = read_8bit_address(device, length = 8)
    try:
        parse_ipmi.parse_header(first_read)
        parse_ipmi.parse_header(second_read)
    except AssertionError:
        try:
            parse_ipmi.parse_header(read_16bit_address(device, length = 8))
        except AssertionError:
            raise AssertionError("No valid IPMI header found in 8 or 16 bit mode")       
        return True
    return False


# Note that it is actively unsafe to call this function until we've verified
# that the target device is not an 8-bit addressed device.
def read_16bit_address(device = 0x50, length = 256):
    # We'll need to start with a two byte address write followed by our first
    # read.  This can then be followed by a sequence of reads.
    bus = smbus2.SMBus(0)

    # Send the address using a custom 2-byte write transaction
    write = smbus2.i2c_msg.write(device, [0, 0])
    bus.i2c_rdwr(write)

    result = []
    while len(result) < length:
        to_read = min(length - len(result), 32)
        result.extend(read_bytes(bus, device, to_read))

    return result


def read_8bit_address(device = 0x50, length = 256):
    bus = smbus2.SMBus(0)
    bus.write_byte(device, 0)

    result = []
    while len(result) < length:
        to_read = min(length - len(result), 32)
        result.extend(read_bytes(bus, device, to_read))

    return result


def read_eeprom(allow_16bit):
    if allow_16bit:
        if detect_16bit():
            eeprom = read_16bit_address()
        else:
            print("Warning: 16 bit set but not detected")
            if allow_16bit > 1:
                eeprom = read_16bit_address()
    else:
        eeprom = read_8bit_address()
    return numpy.array(eeprom, dtype = numpy.uint8)
