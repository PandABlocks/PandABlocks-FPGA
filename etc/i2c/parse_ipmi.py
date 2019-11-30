# Parse IPMI structure
#
# This script implements the parsing of the IPMI FMC EEPROM as documented in
#   [57.1] ANSI/VITA 57.1 FPGA Mezzanine Card (FMC) Standard (revised 2010)
# and
#   [ISD] IPMI Platform Management FRU Information Storage Definition v1.0,
#   Document Revision 1.3, March 24, 2015
#
# This script only supports IPMI fields required by the FMC standard, all other
# fields are ignored.

from __future__ import print_function

import sys
import numpy
import codecs
import string
import datetime

from . import ini_file


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Helper functions

def warn(message):
    print(message, file = sys.stderr)

# Gathers given array of bytes into a single integer.  Works for up to 4 bytes
# in little endian format.
def as_int(bytes):
    result = numpy.zeros((), dtype = numpy.int32)
    for digit in reversed(bytes):
        result = (result << 8) + digit
    return int(result)

# Validates zero sum checksum over given block.
def check_checksum(block, name, checksum = 0):
    settings = numpy.seterr(over = 'ignore')
    assert numpy.sum(block, dtype = numpy.uint8) + checksum == 0, \
        'Checksum error in %s' % name
    numpy.seterr(**settings)

# Takes a list of lists of characters, flattens to a single string.  Kind of
# klunky.
def flatten_ll(ll):
    return ''.join([i for j in ll for i in j])

# Chops a list into segments
def choplist(list, size):
    return [list[i:i+size] for i in range(0, len(list), size)]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# String parsing (type/length byte)

# The parsing of strings is documented in [ISD] section 13.  A string consists
# of a header byte defining the encoding of the string, and parsing is done in
# the context of a language code.

# Implements BCD plus as described in [ISD] section 13.1
def decode_bcd_plus(s):
    mapping = string.digits + ' -.???'
    return flatten_ll([mapping[x & 0xf], mapping[x >> 4]] for x in s)


# Implements 6-bit ASCII as described in [ISD] section 13.2, 13.3
def decode_6bit_ascii(s):
    def convert(x):
        return chr(x + ord(' '))
    return flatten_ll([
        convert(x[0] & 0x3f),
        convert(((x[1] & 0xf) << 2) | (x[0] >> 6)),
        convert(((x[2] & 0x3) << 4) | (x[1] >> 4)),
        convert(x[2] >> 2)] for x in choplist(s, 3))


# Parses a string preceded by a type/length byte, as documented in section 13.
# We don't support the packed encodings, there seems no need for now.
def get_string(data, ix, lang):
    type_length = data[ix]
    ix += 1
    type = type_length >> 6
    length = type_length & 0x3F

    string = data[ix : ix + length]
    # Decode string according to type and lang.
    if type == 0:
        # Nothing to be done for binary
        pass
    elif type == 1:
        string = decode_bcd_plus(string)
    elif type == 2:
        string = decode_6bit_ascii(string)
    elif lang == 0 or lang == 25:
        # English means encoded as latin1
        string = codecs.decode(string, 'latin1')
    else:
        # All other encodings are little-ending UTF-16 (seriously!)
        string = codecs.decode(string, 'utf_16_le')
    return string, ix + length


# Reads a list of strings.
def get_strings(data, ix, language):
    result = []
    while data[ix] != 0xc1:
        s, ix = get_string(data, ix, language)
        result.append(s)
    return result


class StringReader:
    def __init__(self, data, lang_code):
        self.data = data
        self.lang_code = lang_code
        self.ix = 0

    def __iter__(self):
        return self

    def next(self, lang_code = None):
        if self.data[self.ix] == 0xc1:
            raise StopIteration
        else:
            if lang_code is None:
                lang_code = self.lang_code
            result, self.ix = get_string(self.data, self.ix, lang_code)
            return result


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parses the common header defined in [ISD] section 8.

def parse_header(header):
    assert len(header) == 8, 'Invalid header length'
    assert header[0] == 1, 'Invalid header version code'
    if header[1]:
        warn('Ignoring Internal Use Area')
    if header[2]:
        warn('Ignoring Chassis Info Area')
    board_area = header[3]
    assert board_area, 'Missing Board Area'
    product_area = header[4]
    multi_area = header[5]
    assert header[6] == 0, 'Unexpected value in padding'
    check_checksum(header, 'header')
    return (board_area * 8, product_area * 8, multi_area * 8)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parses the board and product info areas defined in [ISD] sections 11 and 12.

# Converts minutes from 1/1/96 into a date string.
def date_string(minutes):
    t = datetime.datetime(1996, 1, 1) + datetime.timedelta(minutes = minutes)
    return t.strftime('%Y-%m-%d %H:%M')

def parse_area_header(data, name):
    assert data[0] == 1, 'Invalid %s Area format' % name
    length = data[1] * 8
    assert length <= len(data), 'Invalid %s Area length' % name
    data = data[:length]
    check_checksum(data, '%s Area' % name)
    return data

def parse_extra_strings(board, reader):
    for i, string in enumerate(reader):
        board['extra %d' % (i + 1)] = string


# Board Info Area [ISD] section 11
def parse_board_area(data):
    data = parse_area_header(data, 'Board')
    lang_code = data[2]
    date_mins = as_int(data[3:6])

    board = ini_file.Section('Board')
    if date_mins:
        board['manufacture date'] = date_string(date_mins)

    reader = StringReader(data[6:], lang_code)
    board['manufacturer'] = reader.next()
    board['product name'] = reader.next()
    board['serial number'] = reader.next(0)
    board['part number'] = reader.next()
    board['fru file id'] = reader.next(0)
    parse_extra_strings(board, reader)
    return board


# Product Info Area [ISD] section 12
def parse_product_area(data):
    data = parse_area_header(data, 'Product')
    lang_code = data[2]

    product = ini_file.Section('Product')
    reader = StringReader(data[3:], lang_code)
    product['manufacturer'] = reader.next()
    product['product name'] = reader.next()
    product['part number'] = reader.next()
    product['version'] = reader.next()
    product['serial number'] = reader.next(0)
    product['asset tag'] = reader.next()
    product['fru file id'] = reader.next(0)
    parse_extra_strings(product, reader)
    return product


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parsers for DC Output and DC Load multi-record types, see [ISD] section 18.2
# and section 18.3 together with [57.1] table 8 for name mapping.

# Mappings from output numbers to section names following [57.1] table 8 and
# rules 5.78, 5.79
dc_load_names = {
    0 : 'VADJ',
    1 : '3P3V',
    2 : '12P0V',
    6 : 'VADJ P2',
    7 : '3P3V P2',
    8 : '12P0V P2',
}
dc_output_names = {
    3 : 'VIO_B_M2C',
    4 : 'VREF_A_M2C',
    5 : 'VREF_B_M2C',
    9 : 'VIO_B_M2C P2',
    10 : 'VREF_A_M2C P2',
    11 : 'VREF_B_M2C P2',
}


# Parses common fields shared between DC Output and DC Load records
def parse_dc_common(result, data):
    assert len(data) == 13, 'Invalid length'
    result['nominal v'] = 1e-2 * as_int(data[1:3])
    result['min v']     = 1e-2 * as_int(data[3:5])
    result['max v']     = 1e-2 * as_int(data[5:7])
    result['pp noise']  = 1e-3 * as_int(data[7:9])
    result['min i']     = 1e-3 * as_int(data[9:11])
    result['max i']     = 1e-3 * as_int(data[11:13])


# Parses DC Load, [ISD] section 18.3
def parse_dc_load(data):
    output = data[0] & 0xf
    result = ini_file.Section(dc_load_names[output])
    parse_dc_common(result, data)
    return result


# Parses DC Output, [ISD] section 18.2
def parse_dc_output(data):
    output = data[0] & 0xf
    result = ini_file.Section(dc_output_names[output])
    parse_dc_common(result, data)
    result['standby'] = bool(data[0] & 0x80)
    return result


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parses the FMC specific multi record defined in [57.1] section 5.5.1, rule
# 5.77, and [ISD] section 18.7.

# Parses subtype 0 defined in [57.1] table 7
def parse_fmc_subtype_0(data):
    assert len(data) == 8, 'Invalid VITA FMC length'
    result = ini_file.Section('FMC IO')
    result['module size'] = data[1] >> 6
    result['p1 size'] = (data[1] >> 4) & 0x3
    result['p2 size'] = (data[1] >> 2) & 0x3    # Note: 3 => not fitted!
    result['clkx bidir'] = bool(data[1] & 2)
    result['p1 a'] = data[2]
    result['p1 b'] = data[3]
    result['p2 a'] = data[4]
    result['p2 b'] = data[5]
    result['p1 gbt'] = data[6] >> 4
    result['p2 gbt'] = data[6] & 0xf
    result['max tck'] = data[7]
    return result

# Parses subtype 1 defined in [57.1] table 9
def parse_fmc_subtype_1(data):
    result = ini_file.Section('FMC Device')
    result['device'] = decode_6bit_ascii(data[1:])
    return result


fmc_subtype_parsers = {
    0 : parse_fmc_subtype_0,
    1 : parse_fmc_subtype_1,
}

def parse_vita_fmc(data):
    assert as_int(data[0:3]) == 0x0012a2, 'Invalid VITA OUI'
    data = data[3:]
    subtype = data[0] >> 4
    return fmc_subtype_parsers[subtype](data)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parses the multi record defined in [ISD] section 16.
# We only need to support the DC Output, DC Load, and the special FMC records.

# Parsers for supported record types
multi_parsers = {
    1 : parse_dc_output,
    2 : parse_dc_load,
    0xFA : parse_vita_fmc,
}


# Parses multi record header: [ISD] section 16.1
def parse_multi_header(data):
    type = data[0]
    flags = data[1]
    end = bool(flags & 0x80)
    assert flags & 0x7F == 2, 'Invalid multi record header'
    length = data[2]
    check_checksum(data, 'Multi Header')
    checksum = data[3]
    return type, length, end, checksum

# Parses a single multi record: parses header, and dispatches to appropriate
# sub-parser.
def parse_multi_record(data):
    type, length, end, checksum = parse_multi_header(data[:5])
    data = data[5 : length + 5]
    check_checksum(data, 'Multi Record', checksum)
    parser = multi_parsers.get(type, None)
    if parser:
        result = parser(data)
    else:
        warn('Ignoring unknown record type %d' % type)
        result = None
    return result, length + 5, end

# Parses entire multi record area and returns list of results
def parse_multi_area(data):
    end = False
    ix = 0
    records = []
    while not end:
        record, length, end = parse_multi_record(data[ix:])
        ix += length
        if record is not None:
            records.append(record)
    return records


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def parse(block):
    board_area, product_area, multi_area = parse_header(block[:8])
    ipmi = ini_file.IniFile()
    ipmi.add_section(parse_board_area(block[board_area:]))
    if product_area:
        ipmi.add_section(parse_product_area(block[product_area:]))
    ipmi.add_sections(parse_multi_area(block[multi_area:]))
    return ipmi

def parse_file(filename):
    block = numpy.fromfile(filename, dtype = numpy.uint8)
    return parse(block)


if __name__ == '__main__':
    ipmi = parse_file(sys.argv[1])
    if len(sys.argv) == 2:
        ipmi.emit()
    else:
        # Compare with ini file
        match = ini_file.load_ini_file(sys.argv[2])
        try:
            ini_file.compare_ini(match, ipmi)
        except ini_file.CompareFail as fail:
            print('Compare failed:', fail)
            sys.exit(1)
        else:
            print('Match ok')
