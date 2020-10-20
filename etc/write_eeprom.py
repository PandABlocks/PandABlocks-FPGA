import argparse
import errno

from i2c import smbus2, eeprom

byte_data = b'\x01\x00\x00\x01\x00\t\x00\xf5\x01\x08\x007\xaa\xc6\xc3DLS\xc824V GPIO\xc40001\xc6DLS24V\xda2020-10-02 11:03:21.271240\xc1\x00\x00\x00\x00W\x02\x02\r\xf7\xf8\x02\xb0\x04t\x04\xec\x04\x00\x00\x00\x00\xe8\x03\x02\x02\r\\\x93\x01J\x019\x01Z\x01\x00\x00\x00\x00\xb8\x0b\x02\x02\rc\x8c\x00\xfa\x00\xed\x00\x06\x01\x00\x00\x00\x00\xa0\x0f\x01\x02\r\xfb\xf5\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\r\xfc\xf4\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\r\xfd\xf3\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfa\x82\x0b\xea\x8f\xa2\x12\x00\x00\x1eD\x00\x00\x00\x00\x00\x00\x00\x00\x00';

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
                readback = eeprom.read_bytes(bus, device, 1)
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
                readback = eeprom.read_bytes(bus, device, 1)
            except OSError as e:
                if not e.errno == errno.ENXIO:  # expected error is no ACK (device not ready for next write)
                    raise e
        assert (len(readback) == 1 and b == readback[0]), "readback data does not match"
        readback = None
        offset += 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='flash data to FMC EEPROM')
    parser.add_argument('--16-bit', dest='sixteenbit', action='store_true', help='16-bit EEPROM')
    args = parser.parse_args()   

    bus = smbus2.SMBus(0)
    if args.sixteenbit:
        write_16bit_address(byte_data)
    else:
        write_8bit_address(byte_data)

