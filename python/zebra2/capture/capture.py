#!/bin/env dls-python
import sys
import socket
from xml.parsers.expat import errors, error, ErrorString

import xml.etree.ElementTree

class Capture(object):
    def __init__(self,hostname, port, output_dir):
        self.data = []
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        # self.line_iter = self.get_lines()
        print 'connecting to {} port {}'.format(hostname, port)

    # def recv_all(self):
    #     ret = [self.line_iter.next()]
    #     assert ret[0], "Connection closed"
    #     if ret[0].startswith("!"):
    #         while not ret[-1].startswith("."):
    #             ret.append(self.line_iter.next())
    #
    # def get_lines(self):
    #     buf = ""
    #     while True:
    #         lines = buf.split("\n")
    #         for line in lines[:-1]:
    #             yield line
    #         buf = lines[-1]
    #         # Get something new from the socket
    #         rx = self.s.recv(4096)
    #         assert rx, "Didn't get response in time"
    #         buf += rx

    def get_data(self):
        msg = "XML\n"
        self.s.sendall(msg)
        while True:
            # msg = raw_input()
            # self.s.sendall(msg)
            # print ">>", msg
            data_stream = self.s.recv(4096)
            if self.parse_data(data_stream): break
        self.close_connection()

    def parse_data(self, data_stream):
        finished = 0
        #get header
        try:
            root = xml.etree.ElementTree.fromstring(data_stream)
            for data_stream in root.iter('data'):
                print "data", data_stream.attrib
            for field in root.iter('field'):
                print "field", field.attrib
        except xml.etree.ElementTree.ParseError, e:
            if ErrorString(e.code) == errors.XML_ERROR_SYNTAX:
                #if it doesn't fit in the xml, check to see if we have the data
                #if we receive OK and we have data, we have reached the end
                if data_stream == 'OK\n' and self.data:
                    print "END REACHED"
                    finished = 1
                self.data.append(data_stream.strip().split(" "))
            else:
                print 'EXCEPTION:', e
                finished = 1
        return finished

    def close_connection(self):
        self.s.close()

    def write_hdf5(self):
        pass

def capture_data(hostname, port, output_dir):
    capture = Capture(hostname, port, output_dir)
    capture.get_data()

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser(
        description="Tool to capture data and write to HDF5")
    parser.add_argument("hostname", default="localhost", nargs="?",
                        help="Hostname of Zebra2 box (default localhost)")
    parser.add_argument("port", type=int, default=8889, nargs="?",
                        help="Port number of TCP server (default 8889)")
    parser.add_argument("output", type=str, default="./output", nargs="?",
                        help="Output directory for HDF5 files")
    args = parser.parse_args()
    capture_data(args.hostname, args.port, args.output)


#connect to the capture stream

#print to a hdf5 file
