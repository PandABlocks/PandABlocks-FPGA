#!/bin/env dls-python

import sys
import os
import socket
from pkg_resources import require
require("numpy")
require("h5py")
import h5py
import unittest

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "python"))

from zebra2.capture import Capture


test_script = os.path.join(os.path.dirname(__file__),  "testseq")

class SystemTest(unittest.TestCase):

    def __init__(self,hostname, cmdport, rcvport, options, reference_hdf):
        name = '{}'.format("<TEST PARAM>")
        setattr(self, name, self.runTest)
        super(SystemTest, self).__init__(name)
        self.options = options
        self.data = []
        self.hdf5_file_path = os.path.join(os.path.dirname(__file__),'hdf5',
                                           reference_hdf)

        #setup connection
        self.cmdsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.cmdsock.connect((hostname, cmdport))
        self.cmdsock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        self.cmdsock.settimeout(1)

        self.rcvsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.rcvsock.connect((hostname, rcvport))
        self.rcvsock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
        self.rcvsock.settimeout(1)

        #load testscript (testseq)
        self.test_script = open(test_script, 'r')

    def send_set_options(self):
        config_msg = " ".join(self.options) + '\n'
        self.rcvsock.sendall(config_msg)
        print "SENDING:", config_msg
        data_stream = self.rcvsock.recv(4096)
        # data_stream = self.get_data()
        print "RECEIVED: ", data_stream

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
            try:
                data_stream = self.rcvsock.recv(4096)
            except socket.timeout:
                break
            input_string += data_stream
            print data_stream.strip()
            if data_stream.startswith("OK"):
                break
        return self.parse_data(input_string.split('\n'))[1]

    def parse_data(self, data_stream):
        header = ""
        data = ""
        for line in data_stream:
            if line.startswith("<"):
                header += line
            elif not line.startswith('OK') and line:
                self.data.append(line.strip().split(" "))
                data = self.data
        return [header, data]

    def check_data(self):
        #open refrence hdf5 file and check that the data matches
        hdf5_file = h5py.File(self.hdf5_file_path,  "r")
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
        self.send_set_options()
        self.send_test_commands()
        self.get_data()
        self.check_data()
        #cleanup
        self.test_script.close()
        self.cmdsock.close()
        self.rcvsock.close()

#generate reference HDF5 file
def generateHDF(hostname,cmdport, rcvport, output_dir):
    print "GENERATING REFERENCE HDF5 FILE"
    capture = Capture(hostname, rcvport, output_dir)
    capture.send_test_commands(hostname, cmdport,test_script)
    capture.run()
    print "REFRENCE HDF5 FILE GENERATED OK"
    return capture.hdf_file

def make_suite():
    hdf_name = generateHDF('localhost', 8888, 8889,
                           os.path.join(os.path.dirname(__file__), 'hdf5'))
    suite = unittest.TestSuite()
    options = [["XML"]]
    options.append(["XML", "FRAMED", "SCALED"])
    options.append(["XML", "FRAMED", "UNSCALED"])
    options.append(["XML", "ASCII", "SCALED"])
    for option in options:
        print "OPTION", option
        testcase = SystemTest('localhost', 8888, 8889, option, hdf_name)
        suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(make_suite())
    sys.exit(not result.wasSuccessful())
