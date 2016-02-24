#!/bin/env dls-python
import sys, os
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
        self.output_dir = output_dir
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        print 'connecting to {} port {}'.format(hostname, port)

    def run(self):
        self.set_options()
        self.get_data()

    def set_options(self):
        #set the header to XML format
        msg = "XML\n"
        self.s.sendall(msg)

    def get_data(self):
        while True:
            data_stream = self.s.recv(4096)
            if self.parse_data(data_stream): break
        self.close_connection()
        self.write_hdf5(self.data)

    def parse_data(self, data_stream):
        finished = 0
        try:
            #get the header
            root = xml.etree.ElementTree.fromstring(data_stream)
            # for data_stream in root.iter('data'):
            #     print "data", data_stream.attrib
            # for field in root.iter('field'):
            #     print "field", field.attrib
        except xml.etree.ElementTree.ParseError, e:
            if ErrorString(e.code) == errors.XML_ERROR_SYNTAX:
                #if it doesn't fit in the xml, check to see if we have the data
                #if we receive OK and we have data, we have reached the end
                if data_stream == 'OK\n' and self.data:
                    print "END REACHED"
                    finished = 1
                elif data_stream != 'OK\n':
                    # print "dATA", data_stream
                    self.data.append(data_stream.strip().split(" "))
                    print data_stream.strip()
            else:
                print 'EXCEPTION:', e
                finished = 1
        return finished

    def close_connection(self):
        self.s.close()

    def create_output_directory(self, dir):
        if not os.path.exists(dir):
            os.makedirs(dir)

    def write_hdf5(self, data):

        self.create_output_directory(self.output_dir)

        HDF5_FILE = os.path.join(self.output_dir, self.get_timestamp() + '.hdf5')

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


#connect to the capture stream

#print to a hdf5 file
