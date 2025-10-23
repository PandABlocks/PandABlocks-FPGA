#!/usr/bin/env python
# this script generates a read command's data for the secure EEPROM atsha240a
#
# Find datasheet in:
# https://ww1.microchip.com/downloads/en/DeviceDoc/ATSHA204A-Data-Sheet-40002025A.pdf
# Product page:
# https://www.microchip.com/en-us/product/ATSHA204A

import argparse

# Usual request is form of:
# WORD_ADDRESS + SIZE + OPCODE + PARAM1 + PARAM2 + CRC16
SIZE_OF_WORD_ADDRESS = 1
SIZE_OF_SIZE = 1
SIZE_OF_OPCODE = 1
SIZE_OF_PARAM1 = 1
SIZE_OF_PARAM2 = 2
SIZE_OF_CHECKSUM = 2

# Word address byte
# "Reset the address counter. The next read or write transaction starts with the
#  beginning of the I/O buffer.", this could be useful to reread the data
WORD_ADDRESS_RESET = 0x0
# "Write subsequent bytes to sequential addresses in the input command buffer
#  that follow previous writes. This is the normal operation."
WORD_ADDRESS_COMMAND = 0x3
WORD_ADDRESS_SIZE = 1

# Opcode byte
# Read 4 or 32 bytes from the device
OPCODE_READ = 0x2
# Write 4 or 32 bytes from the device
OPCODE_WRITE = 0x12

# Size byte
READ_REQUEST_SIZE = SIZE_OF_SIZE + SIZE_OF_OPCODE \
    + SIZE_OF_PARAM1 + SIZE_OF_PARAM2 + SIZE_OF_CHECKSUM


PARAM1_ZONE_CONFIG = 0x00
PARAM1_ZONE_OTP = 0x01
PARAM1_ZONE_DATA = 0x02
PARAM1_32B_REQUEST = 0x80

PARAM2_BLOCK_BIT_OFFSET = 3
PARAM2_OFFSET_BIT_OFFSET = 0
# Second byte of param2 is always 0
PARAM2_BYTE2 = 0


def zone_arg_to_param1(opt):
    if opt == 'config':
        return PARAM1_ZONE_CONFIG

    if opt == 'data':
        return PARAM1_ZONE_DATA

    return PARAM1_ZONE_OTP


def int_or_hex(opt):
    if opt.startswith('0x'):
        return int(opt, 16)
    else:
        return int(opt)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--zone', choices=['config', 'otp', 'data'],
                        default='otp')
    parser.add_argument('--block', type=int_or_hex, default=0,
                        help='Specify the block to read or write')
    return parser.parse_args()


def crc16(data):
    res = 0
    for b in data:
        for i in range(8):
            data_bit = (b >> i) & 1
            crc_bit = (res >> 15) & 1
            res <<= 1
            if data_bit ^ crc_bit:
                res ^= 0x8005

    return res & 0xffff


def main():
    args = parse_args()
    data = bytearray()
    data.append(WORD_ADDRESS_COMMAND)
    data.append(READ_REQUEST_SIZE)
    data.append(OPCODE_READ)
    data.append(PARAM1_32B_REQUEST | zone_arg_to_param1(args.zone))
    # Given we are reading 32 bytes, offset is 0 (alignment is mandatory)
    data.append(args.block << PARAM2_BLOCK_BIT_OFFSET)
    data.append(PARAM2_BYTE2)
    # crc doesn't cover the first byte
    crc_val = crc16(bytes(data[1:]))
    data.append(crc_val & 0xff)
    data.append((crc_val >> 8) & 0xff)
    # print the result hex-formatted
    for item in bytes(data):
        print(f'0x{item:02x} ', end='')
    print()


if __name__ == '__main__':
    main()
