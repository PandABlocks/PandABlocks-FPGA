#!/bin/env dls-python

import sys
import os
import socket
from pkg_resources import require
require("numpy")
require("h5py")
import h5py
# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "python"))

import unittest

REFERENCE_HDF5 = "20160229092339.hdf5"
hdf5_file_path = os.path.join(os.path.dirname(__file__),"..", "..", "python", "zebra2",
                        "capture", "hdf5", REFERENCE_HDF5)

test_script = os.path.join(os.path.dirname(__file__),  "testseq")

class SystemTest(unittest.TestCase):

    def __init__(self,hostname, cmdport, rcvport, options):
        name = '{}'.format("<TEST PARAM>")
        setattr(self, name, self.runTest)
        super(SystemTest, self).__init__(name)
        self.options = options
        self.data = []

        #setup connection
        self.cmdsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.cmdsock.connect((hostname, cmdport))
        self.cmdsock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        self.rcvsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.rcvsock.connect((hostname, rcvport))
        self.rcvsock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        #load testscript (testseq)
        self.test_script = open(test_script, 'r')

    def send_set_options(self):
        for option in self.options:
            config_msg = option + "\n"
            self.rcvsock.sendall(config_msg)
            # print "SENDING:", config_msg
            data_stream = self.rcvsock.recv(4096)
            # print "RECEIVED: ", data_stream

    def send_test_commands(self):
        #send the test commands
        for line in self.test_script:
            self.cmdsock.sendall(line)
            if line[:1].isdigit() or "TABLE<" in line:
                pass
                # print "TABLE", line
            else:
                # print "SENDING:", line
                data_stream = self.cmdsock.recv(4096)
                # print "RECEIVED: ", data_stream

    def get_data(self):
        input_string = ""
        data_start = False
        while True:
            data_stream = self.rcvsock.recv(4096)
            input_string += data_stream
            print data_stream.strip()
            if data_stream.startswith("OK"):
                break
        self.parse_data(input_string.split('\n'))

    def parse_data(self, data_stream):
        header = ""
        for line in data_stream:
            if line.startswith("<"):
                header += line
            elif not line.startswith('OK') and line:
                self.data.append(line.strip().split(" "))

    def check_data(self):
        self.open_hdf5_file()

    def open_hdf5_file(self):
        #open refrence hdf5 file
        hdf5_file = h5py.File(hdf5_file_path,  "r")
        for item in hdf5_file.attrs.keys():
            print item + ":", hdf5_file.attrs[item]
        counts = hdf5_file['/Scan/data/counts']
        positions = hdf5_file['/Scan/data/positions']
        print "{}\t{}\t{}".format("\n#", "counts", "positions")
        for i in range(len(counts)):
            self.assertEqual(counts[i], self.data[i][0])#MAKE SURE THE REFERENCE FILE USED THE SAME SETTINGS HERE
            print "{}\t{}\t{}".format(i, counts[i], positions[i])
        hdf5_file.close()

    #RENAME
    def runTest(self):
        #send specific test config
        self.send_set_options()
        #start sending lines from the testscript
        self.send_test_commands()
        #get the data
        self.get_data()
        #check to see if the data is the same as in the refrence hdf5 file
        self.check_data()
        #cleanup
        self.test_script.close()
        self.cmdsock.close()
        self.rcvsock.close()

def make_suite():
    suite = unittest.TestSuite()
    options = ["XML"]
    testcase = SystemTest('localhost', 8888, 8889, options)
    suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(make_suite())
    sys.exit(not result.wasSuccessful())
