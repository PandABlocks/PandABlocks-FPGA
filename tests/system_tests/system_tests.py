#!/bin/env dls-python

import sys
import os
import socket
import struct
from pkg_resources import require
require("numpy")
require("h5py")
import h5py
import unittest
import xml.etree.ElementTree

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "python"))

from zebra2.capture import Capture, DataHandler


test_script = os.path.join(os.path.dirname(__file__),  "testseq")

class SystemTest(unittest.TestCase):

    def __init__(self,hostname, cmdport, rcvport, options, reference_hdf):
        name = '{}'.format(' '.join(options))
        setattr(self, name, self.runTest)
        super(SystemTest, self).__init__(name)
        self.options = options
        self.header_fields = []
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

        #make capture object
        #self.capture = Capture()
        self.dataHandler = DataHandler()

    def send_set_options(self):
        config_msg = " ".join(self.options) + '\n'
        self.rcvsock.sendall(config_msg)
        data_stream = self.rcvsock.recv(4096)

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

    def check_data(self):
        #open refrence hdf5 file and check that the data matches
        hdf5_file = h5py.File(self.hdf5_file_path,  "r")
        for item in hdf5_file.attrs.keys():
            print item + ":", hdf5_file.attrs[item]
        counts = hdf5_file['/Scan/data/counts']
        positions = hdf5_file['/Scan/data/positions']
        # print "{}\t{}\t{}".format("\n#", "counts", "positions")
        for i in range(len(counts)):
            #rescale data
            if self.dataHandler.header_data['process'] == 'Unscaled':
                self.dataHandler.data[i][0] =  self.dataHandler.data[i][0]/ 125000000.0
            self.assertEqual(counts[i], str(self.dataHandler.data[i][0]))
            self.assertEqual(float(positions[i]), float(self.dataHandler.data[i][1]))
            # print "{}\t{}\t{}".format(i, counts[i], self.data[i][0])
        hdf5_file.close()

    #RENAME
    def runTest(self):
        self.send_set_options()
        self.send_test_commands()
        self.dataHandler.get_data(self.rcvsock)
        self.check_data()
        #cleanup
        self.test_script.close()
        self.cmdsock.close()
        self.rcvsock.close()

#generate reference HDF5 file
def generateHDF(hostname,cmdport, rcvport, output_dir, output_name):
    print "GENERATING REFERENCE HDF5 FILE"
    capture = Capture(hostname, rcvport, output_dir, output_name)
    capture.send_test_commands(hostname, cmdport,test_script)
    capture.run()
    print "REFRENCE HDF5 FILE GENERATED OK"
    return capture.hdf_file

def make_suite():
    #generate hdf5 file if not present, otherwise use the one that is there
    hdf_name = 'reference.hdf5'
    if not os.path.isfile('hdf5/reference.hdf5'):
        hdf_name = generateHDF('localhost', 8888, 8889,
                               os.path.join(os.path.dirname(__file__), 'hdf5'),
                               'reference')
    suite = unittest.TestSuite()
    options = [["XML"]]
    options.append(["XML", "FRAMED", "SCALED"])
    options.append(["XML", "FRAMED", "UNSCALED"])
    options.append(["XML", "ASCII", "SCALED"])
    for option in options:
        testcase = SystemTest('localhost', 8888, 8889, option, hdf_name)
        suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(make_suite())
    sys.exit(not result.wasSuccessful())
