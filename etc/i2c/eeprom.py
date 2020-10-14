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
#    The code below relies on undocumented behaviour that we are seeing on the
# M24C64: writing a single byte appears to reset the entire page address (32 bit
# transfer pages), but not the byte offset within the page.
#    Therefore the trick here is to read half of the same page twice using
# single byte addressing: if we get the same result both times then assume that
# this is ok, otherwise fall back to two byte addressing.
def detect_16bit(device = 0x50):
    # Read two half pages.  If they are the same then we can assume that we were
    # able to reset
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

def detect_16bit_bruteforce(device = 0x50):
    bus = smbus2.SMBus(0)
    read = smbus2.i2c_msg.read(device, 128)
    data = []
    while len(data) < 65536:
        bus.i2c_rdwr(read)
        data.extend(list(read))

    for page in range(256):
        if data[(page*256):((page+1)*256)] != data[:256]:
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


# Note that it is actively unsafe to call this function until we've verified
# that the target device is not an 8-bit addressed device.
def write_16bit_address(data, device = 0x50):
    # We'll need to start with a two byte address write followed by our first
    # read.  This can then be followed by a sequence of reads.
    bus = smbus2.SMBus(0)
    offset = 0
    readback = None
    for b in data:
        write = smbus2.i2c_msg.write(device, [0, offset, b])
        bus.i2c_rdwr(write)
        while readback is None:
            try:   
                write = smbus2.i2c_msg.write(device, [0, offset])
                bus.i2c_rdwr(write)
                readback = read_bytes(bus, device, 1)
            except OSError as e:
                if not e.errno == errno.ENXIO:  # expected error is no ACK
                    raise e
        assert (len(readback) == 1 and b == readback[0]), "readback data does not match"
        readback = None
        offset += 1


def read_8bit_address(device = 0x50, length = 256):
    bus = smbus2.SMBus(0)
    bus.write_byte(device, 0)

    result = []
    while len(result) < length:
        to_read = min(length - len(result), 32)
        result.extend(read_bytes(bus, device, to_read))

    return result


def write_8bit_address(data, device = 0x50):
    bus = smbus2.SMBus(0)
    offset = 0
    readback = None
    for b in data:        
        write = smbus2.i2c_msg.write(device, [offset, b])
        bus.i2c_rdwr(write)
        while readback is None:
            try:               
                bus.write_byte(device, offset)
                readback = read_bytes(bus, device, 1)
            except OSError as e:
                if not e.errno == errno.ENXIO:  # expected error is no ACK
                    raise e
        
        assert b == readback, "readback data does not match"
        readback = None
        offset += 1


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
