import argparse
import errno

from i2c import smbus2, eeprom, inifile, create_ipmi


def write_8bit_address(data, device=0x50):
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
                # expected error is no ACK (device not ready for next write)
                if not e.errno == errno.ENXIO:
                    raise e

        assert b == readback, "readback data does not match"
        readback = None
        offset += 1


def write_16bit_address(data, device=0x50):
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
                # expected error is no ACK (device not ready for next write)
                if not e.errno == errno.ENXIO:
                    raise e
        assert len(readback) == 1 and b == readback[0], \
            "readback data does not match"
        readback = None
        offset += 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='flash data to FMC EEPROM')
    parser.add_argument(
        '--16-bit', dest='sixteenbit', action='store_true',
        help='16-bit EEPROM'
    )
    args = parser.parse_args()
    ini = ini_file.load_ini_file(sys.argv[1])
    ipmi = create_ipmi.generate_ipmi(ini)

    bus = smbus2.SMBus(0)
    if args.sixteenbit:
        write_16bit_address(ipmi)
    else:
        write_8bit_address(ipmi)
