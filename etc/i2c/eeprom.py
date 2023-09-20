# Helper for reading EEPROM

import errno
import numpy
import time

from . import smbus2

I2C_BUSY_TIMEOUT_S = 1.0


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
            if time.time() >= start_time + I2C_BUSY_TIMEOUT_S:
                raise TimeoutError('read_address: i2c timeout')

    result = []
    while len(result) < length:
        to_read = min(length - len(result), 32)
        result.extend(read_bytes(bus, device, to_read))

    return result


def write_address(device=0x50, data=[], address16bit=False):
    bus = smbus2.SMBus(0)
    offset = 0
    while offset < len(data):
        address_data = [offset]
        if address16bit:
            address_data = [(offset >> 8) & 0xff, offset & 0xff]
        else:
            address_data =  [ offset & 0xff ]

        start_time = time.time()
        while device_is_busy(bus, device):
            if time.time() >= start_time + I2C_BUSY_TIMEOUT_S:
                raise TimeoutError('write_address: i2c timeout')

        write_bytes(bus, device, address_data + list(data[offset:offset + 32]))
        offset += 32


def read_eeprom(length=256):
    eeprom = read_address(length=length)
    return numpy.array(eeprom, dtype = numpy.uint8)
