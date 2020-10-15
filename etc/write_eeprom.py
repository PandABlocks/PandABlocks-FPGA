# Writes data piped from stdin to EEPROM...good luck

from sys import stdin

from i2c import smbus2


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
                if not e.errno == errno.ENXIO:  # expected error is no ACK (device not ready for next write)
                    raise e
        
        assert b == readback, "readback data does not match"
        readback = None
        offset += 1


def write_16bit_address(data, device = 0x50):
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
                if not e.errno == errno.ENXIO:  # expected error is no ACK (device not ready for next write)
                    raise e
        assert (len(readback) == 1 and b == readback[0]), "readback data does not match"
        readback = None
        offset += 1


if __name__ == "__main__":
    byte_data = stdin.buffer.read()

    bus = smbus2.SMBus(0)
    if eeprom.detect_16bit():
        write_16bit_address(byte_data)
    else:
        write_8bit_address(byte_data)

