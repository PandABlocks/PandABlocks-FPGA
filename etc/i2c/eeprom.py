# Helper for reading EEPROM

import errno
import numpy
import time

from . import smbus2


def read_bytes(bus, device, length = 32):
    read = smbus2.i2c_msg.read(device, length)
    bus.i2c_rdwr(read)
    return list(read)


def write_bytes(bus, device, data):
    write = smbus2.i2c_msg.write(device, data)
    bus.i2c_rdwr(write)


def device_is_busy(bus, device):
    try:
        write_bytes(bus, device, [0])
    except OSError as e:
        # Device not ready for next write or just missing
        if e.errno == errno.ENXIO:
            return True

    return False


def read_address(device=0x50, length=256):
    bus = smbus2.SMBus(0)
    # This is a trick to deal with 16-bit address EEPROMs, as the address is
    # implemented in hardware as a shift register we can reset the address
    # by writing zero in several transactions without risking overriding
    # data in a 32-bit address EEPROM
    for _ in range(4):
        start_time = time.time()
        # this writes 1 zero to check if the device is busy
        while device_is_busy(bus, device):
            if time.time() >= start_time + 1.0:
                raise TimeoutError('i2c timeout while writing')

    result = []
    while len(result) < length:
        to_read = min(length - len(result), 32)
        result.extend(read_bytes(bus, device, to_read))

    return result



def read_eeprom(length=256):
    eeprom = read_address(length=length)
    return numpy.array(eeprom, dtype = numpy.uint8)
