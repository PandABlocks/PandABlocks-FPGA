#!/usr/bin/env python
import sys, os, re
import socket
from xml.parsers.expat import errors, ErrorString
import datetime
import struct

from pkg_resources import require
require("h5py")
import h5py
import numpy



import xml.etree.ElementTree

class Capture(object):
    def __init__(self,hostname, port, output_dir, output_name):
        self.output_dir = output_dir
        # self.output_name = output_name
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        #self.s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        # self.s.settimeout(1)
        # print 'connecting to {} port {}'.format(hostname, port)

        self.dataHandler = DataHandler(hdfout = output_name)

    def run(self):
        self.set_options()
        self.dataHandler.get_data(self.s)
        self.dataHandler.write_hdf5(self.output_dir)

    def set_options(self):
        #set the header to XML format
        msg = "XML\n"
        self.s.sendall(msg)

    def close_connection(self):
        self.s.close()

    def create_output_directory(self, dir):
        if not os.path.exists(dir):
            os.makedirs(dir)

    def send_test_commands(self, host, port, test_script_path):
        try:
            test_script = open(test_script_path, 'r')
            cmdsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            cmdsock.connect((host, port))
            cmdsock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
            cmdsock.settimeout(1)
            #send the test commands
            for line in test_script:
                cmdsock.sendall(line)
                if line[:1].isdigit() or "TABLE<" in line:
                    pass
                    # print "TABLE", line
                else:
                    data_stream = cmdsock.recv(4096)
            cmdsock.close()
        except Exception as e:
            cmdsock.close()
            print "Exception: ", e



class DataHandler(object):
    def __init__(self, hdfout = ""):
        self.output_name = hdfout
        self.data = []
        self.header_fields = []
        self.hdf_file = ""

    def get_data(self, rcvsock):
        data_stream = ""
        while True:
            #this section should be made to match exactly what is expected
            try:
                data_stream = rcvsock.recv(4096)
                print [data_stream]
                if data_stream.startswith("END"):
                    break
            except socket.timeout:
                break
            if data_stream.startswith("<"):
                self.parse_header(data_stream)
            elif data_stream.startswith("BIN"):
                self.data += self.parse_binary(data_stream.strip('BIN '))
            elif data_stream.startswith("OK"):
                #we are just getting the aknowledgement from the options
                pass
            else:
                self.data += self.parse_data(data_stream)

    def parse_data(self, data_stream):
        if not data_stream.startswith('OK') and data_stream:
            return [data_stream.strip().split(" ")[i:i+len(self.header_fields)]
                    for i in range(0, len(data_stream.strip().split(" ")),
                                   len(self.header_fields))]

    def parse_header(self, header):
        try:
            #get the header
            root = xml.etree.ElementTree.fromstring(header)
            for header_data in root.iter('data'):
                self.header_data = header_data.attrib
            for field in root.iter('field'):
                self.header_fields.append(field.attrib)
        except xml.etree.ElementTree.ParseError, e:
            print 'EXCEPTION:', e

    def parse_binary(self, binary_stream):
        binary_data = []
        fmt, data_size = self.get_bin_unpack_fmt()
        #find the packet length from the first 4 bits
        packet_length = struct.unpack('<I', binary_stream[0:4])[0]
        print "PACKET LENGTH: ", packet_length
        #strip off the first 4 bits which hold the packet length
        actual_data = binary_stream[4:len(binary_stream)]
        #split the data
        split_data = [
            actual_data[x:x+data_size]
            for x in range(0,len(actual_data),data_size)]
        for section in split_data:
            binary_data.append(list(struct.unpack(fmt, section)))
        return binary_data

    def get_bin_unpack_fmt(self):
        format_chars = {
            'int32': 'i',
            'uint32': 'I',
            'int64': 'q',
            'uint64': 'Q',
            'double': 'd'}
        fmt = '<'
        expected_data_size = 0
        for field in self.header_fields:
            fmt += format_chars[field['type']]
        expected_data_size = int(self.header_data['sample_bytes'])
        return fmt, expected_data_size

    def get_timestamp(self):
        import time
        ts = time.time()
        st = datetime.datetime.fromtimestamp(ts).strftime('%Y%m%d%H%M%S')
        return st

    def write_hdf5(self, output_dir):
        # self.create_output_directory(self.output_dir)
        if self.output_name == 'reference':
            self.hdf_file = 'reference.hdf5'
        else:
            self.hdf_file = self.get_timestamp() + '.hdf5'
        HDF5_FILE = os.path.join(output_dir, self.hdf_file)

        npdata = numpy.array(self.data)


        f = h5py.File(HDF5_FILE, "w")  # create the HDF5 NeXus file
        nxentry = f.create_group('Capture')
        nxentry.attrs["NX_class"] = 'NXentry'
        nxdata = nxentry.create_group('data')
        nxdata.attrs["NX_class"] = 'NXdata'

        col = []

        #make sections for each captured field
        for idx, field in enumerate(self.header_fields):

            nxdata.attrs['signal'] = field['name']

            col.append(nxdata.create_dataset(field['name'],
                                             data=numpy.array(npdata[:,idx])))
            if 'units' in field.keys():
                col[idx].attrs['units'] = field['units']


        f.close()


def capture_data(hostname, port, output_dir, output_name):
    capture = Capture(hostname, port, output_dir, output_name)
    capture.create_output_directory(output_dir)
    capture.run()

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser(
        description="Tool to capture data and write to HDF5")
    parser.add_argument("hostname", default="localhost", nargs="?",
                        help="Hostname of Zebra2 box (default localhost)")
    parser.add_argument("port", type=int, default=8889, nargs="?",
                        help="Port number of TCP server (default 8889)")
    parser.add_argument("output_dir", type=str, default="hdf5", nargs="?",
                        help="Output directory for HDF5 files")
    parser.add_argument("output_name", type=str, default="timestamp", nargs="?",
                        help="Name mode of the output file. "
                             "timestamp = name based on timestamp,"
                             "reference = 'reference.hdf5'")
    args = parser.parse_args()
    capture_data(args.hostname, args.port, args.output_dir, args.output_name)

