#!/bin/env dls-python
import sys, os, re
import socket
from xml.parsers.expat import errors, ErrorString
import datetime

from pkg_resources import require
require("h5py")
import h5py
import numpy


import xml.etree.ElementTree

class Capture(object):
    def __init__(self,hostname, port, output_dir):
        self.data = []
        self.hdf_file = ""
        self.output_dir = output_dir
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        # self.s.settimeout(1)
        print 'connecting to {} port {}'.format(hostname, port)

    def run(self):
        self.set_options()
        self.get_data()

    def set_options(self):
        #set the header to XML format
        msg = "XML\n"
        self.s.sendall(msg)

    def get_data(self):
        input_string = ""
        data_start = False
        while True:
            data_stream = self.s.recv(4096)
            input_string += data_stream
            print data_stream.strip()
            if data_stream.startswith("END") and data_start:
                break
            elif data_stream.startswith('OK'):
                data_start = True
        self.parse_data(input_string.split('\n'))
        self.close_connection()
        self.write_hdf5(self.data)

    def parse_data(self, data_stream):
        header = ""
        for line in data_stream:
            if line:
                if line.startswith("<"):
                    header += line
                elif not line.startswith('OK') and not line.startswith("END"):
                    self.data.append(line.strip().split(" "))
        try:
            #get the header
            root = xml.etree.ElementTree.fromstring(header)
            # for data_stream in root.iter('data'):
            #     print "data", data_stream.attrib
            # for field in root.iter('field'):
            #     print "field", field.attrib
        except xml.etree.ElementTree.ParseError, e:
            print 'EXCEPTION:', e

    def close_connection(self):
        self.s.close()

    def create_output_directory(self, dir):
        if not os.path.exists(dir):
            os.makedirs(dir)

    def write_hdf5(self, data):

        self.create_output_directory(self.output_dir)
        self.hdf_file = self.get_timestamp() + '.hdf5'
        HDF5_FILE = os.path.join(self.output_dir, self.hdf_file)

        npdata = numpy.array(data)
        print "NPDATA", npdata
        positions = numpy.array(npdata[:,1])
        counts = numpy.array(npdata[:,0])

        f = h5py.File(HDF5_FILE, "w")  # create the HDF5 NeXus file
        nxentry = f.create_group('Scan')
        nxentry.attrs["NX_class"] = 'NXentry'

        nxdata = nxentry.create_group('data')
        nxdata.attrs["NX_class"] = 'NXdata'
        nxdata.attrs['signal'] = "position"
        nxdata.attrs['axes'] = "counts"

        pos = nxdata.create_dataset("positions", data=positions)
        pos.attrs['units'] = "units"

        counts = nxdata.create_dataset("counts", data=counts)
        counts.attrs['units'] = "counts"
        f.close()

    def get_timestamp(self):
        import time
        ts = time.time()
        st = datetime.datetime.fromtimestamp(ts).strftime('%Y%m%d%H%M%S')
        return st

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

def capture_data(hostname, port, output_dir):
    capture = Capture(hostname, port, output_dir)
    capture.run()

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser(
        description="Tool to capture data and write to HDF5")
    parser.add_argument("hostname", default="localhost", nargs="?",
                        help="Hostname of Zebra2 box (default localhost)")
    parser.add_argument("port", type=int, default=8889, nargs="?",
                        help="Port number of TCP server (default 8889)")
    parser.add_argument("output", type=str, default="hdf5", nargs="?",
                        help="Output directory for HDF5 files")
    args = parser.parse_args()
    capture_data(args.hostname, args.port, args.output)

