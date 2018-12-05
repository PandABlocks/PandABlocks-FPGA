# Create IPMI structure
#
# This script implements the generation of an IPMI FMC EEPROM as documented in
#   [57.1] ANSI/VITA 57.1 FPGA Mezzanine Card (FMC) Standard (revised 2010)
# and
#   [ISD] IPMI Platform Management FRU Information Storage Definition v1.0,
#   Document Revision 1.3, March 24, 2015

import sys
import numpy
import codecs
import itertools
import datetime
import dateutil.parser


def zeros(count):
    return numpy.zeros(count, dtype = numpy.uint8)

def append(base, value):
    return numpy.append(base, numpy.array(value, dtype = numpy.uint8))

def checksum(data):
    return -data.sum() & 0xff

def int16(value, scale):
    value = float(value) * scale
    return numpy.int16([value]).view(dtype = numpy.uint8)

def compute_time(datestr):
    epoch = datetime.datetime(1996, 1, 1)
    date_epoch = dateutil.parser.parse(datestr) - epoch
    try:
        delta = date_epoch.total_seconds() / 60
    except AttributeError:
        # Python 2.6 doesn't have total_seconds
        delta = date_epoch.days * 24 * 60 + date_epoch.seconds / 60
    return numpy.int32([delta]).view(dtype = numpy.uint8)[:3]


class Area(object):
    def __init__(self, size = 0):
        self.area = zeros(size)

    def __setitem__(self, key, value):
        self.area[key] = value

    def __getitem__(self, key):
        return self.area[key]

    def __len__(self):
        return len(self.area)

    def append(self, value):
        self.area = append(self.area, value)

    # Add type/length and string to given area
    def add_string(self, string):
        string = codecs.encode(string, 'latin1')
        if len(string) == 1:
            string += ' '
        assert len(string) <= 0x3f
        encoding = zeros(len(string) + 1)
        encoding[0] = 0xc0 + len(string)
        encoding[1:] = numpy.fromstring(string, dtype = numpy.uint8)
        self.append(encoding)

    # Zero pad so that the total length is a multiple of 8 and allow for a
    # checksum byte at the end.  The length in 8-byte blocks is returned.
    def pad_to_length(self):
        l = len(self.area)
        blocks = (l + 8) / 8
        self.append(zeros(8 * blocks - l))
        return blocks

    # Completes the generation of an area by padding with zeros and adding a
    # final checksum character.  The final length is a multiple of 8.
    def wrapup(self):
        l = len(self.area)
        padding = 8 * ((l + 8) / 8) - l
        self.append(zeros(padding))
        self.area[-1] = checksum(self.area[:-1])



def generate_board_area(ini):
    # Prepare header
    board = Area(6)
    board[0] = 1
    # Fill in length at end
    board[2] = 25       # English (latin1 encoding)
    board[3:6] = compute_time(ini['manufacture date'])

    # Output the strings
    board.add_string(ini['manufacturer'])
    board.add_string(ini['product name'])
    board.add_string(ini['serial number'])
    board.add_string(ini['part number'])
    board.add_string(ini['fru file id'])
    for i in itertools.count(1):
        try:
            board.add_string(ini['extra %d' % i])
        except KeyError:
            break

    # Now wrap up the board: add final end of string marker followed by size
    # padding and checksum.
    board.append(0xc1)
    board.pad_to_length()
    board[1] = len(board) / 8
    board[-1] = checksum(board[:-1])
    return board.area


def create_record_header(type, length, end):
    header = Area(5)
    header[0] = type
    header[1] = (end << 7) | 2
    header[2] = length
    # Remaining fields to be filled in later
    return header

def complete_record(area, header, body):
    header[3] = checksum(body[:])
    header[4] = checksum(header[:-1])
    area.append(header.area)
    area.append(body.area)

def add_dc_common(area, header, output, ini, standby = False):
    body = Area(13)
    body[0] = output | (standby << 7)
    body[1:3]   = int16(ini['nominal v'],  100)
    body[3:5]   = int16(ini['min v'],  100)
    body[5:7]   = int16(ini['max v'],  100)
    body[7:9]   = int16(ini['pp noise'],  1000)
    body[9:11]  = int16(ini['min i'],  1000)
    body[11:13] = int16(ini['max i'],  1000)
    complete_record(area, header, body)

def add_dc_output(area, output, ini, end = False):
    header = create_record_header(1, 13, end)
    standby = ini['standby'] == 'True'
    add_dc_common(area, header, output, ini, standby)

def add_dc_load(area, output, ini, end = False):
    header = create_record_header(2, 13, end)
    add_dc_common(area, header, output, ini)


def add_vita_fmc0(area, ini, end = False):
    header = create_record_header(0xfa, 11, end)
    body = Area(11)
    body[0:3] = numpy.array([0xa2, 0x12, 0x00], dtype = numpy.uint8)
    view = body[3:]
    view[0] = 0         # Subtype 0
    view[1] = \
        ((int(ini['module size']) & 0x3) << 6) | \
        ((int(ini['p1 size']) & 0x3) << 4) | \
        ((int(ini['p2 size']) & 0x3) << 2) | \
        (((ini['clkx bidir'] == 'True') & 0x1) << 1)
    view[2] = int(ini['p1 a'])
    view[3] = int(ini['p1 b'])
    view[4] = int(ini['p2 a'])
    view[5] = int(ini['p2 b'])
    view[6] = ((int(ini['p1 gbt']) & 0xF) << 4) | (int(ini['p2 gbt']) & 0xf)
    view[7] = int(ini['max tck'])
    complete_record(area, header, body)


def generate_multi_area(ini):
    area = Area()
    add_vita_fmc0(area, ini['FMC IO'])
    add_dc_load(area, 0, ini['VADJ'])
    add_dc_load(area, 1, ini['3P3V'])
    add_dc_load(area, 2, ini['12P0V'])
    add_dc_output(area, 3, ini['VIO_B_M2C'])
    add_dc_output(area, 4, ini['VREF_A_M2C'])
    add_dc_output(area, 5, ini['VREF_B_M2C'], end = True)
    area.wrapup()
    return area.area


def generate_header(board, multi):
    header = zeros(8)
    header[0] = 1       # Format version 1
    header[1] = 0       # No internal use
    header[2] = 0       # No chassis info
    header[3] = 1       # Board area directly follows header
    header[4] = 0       # No product info area
    assert len(board) % 8 == 0
    header[5] = len(board) / 8 + 1
    header[6] = 0
    header[7] = checksum(header[:7])
    return header


def generate_ipmi(ini):
    board = generate_board_area(ini['Board'])
    multi = generate_multi_area(ini)
    header = generate_header(board, multi)
    return numpy.concatenate((header, board, multi))


if __name__ == '__main__':
    import ini_file
    ini = ini_file.load_ini_file(sys.argv[1])
    ipmi = generate_ipmi(ini)
    if len(sys.argv) == 2:
        print ipmi
    else:
        ipmi.tofile(sys.argv[2])
