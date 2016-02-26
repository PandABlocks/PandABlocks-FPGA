#!/bin/env dls-python

import sys
import os
import socket
from pkg_resources import require
require("numpy")

# add our python dir
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "python"))

import unittest

hdf5_dir = os.path.join(os.path.dirname(__file__),  "..", "python", "zebra2",
                        "capture", "hdf5")

class SystemTest(unittest.TestCase):

    def __init__(self,hostname, port):
        name = '{}'.format("<TEST PARAM>")
        setattr(self, name, self.runTest)
        super(SystemTest, self).__init__(name)

        #setup connection
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        #load testscript (testseq)

    def send_test_commands(self):
        #send the test commands here
        pass

    def get_data(self):
        pass

    def check_data(self):
        pass

    #RENAME
    def runTest(self):
        #send specific test config
        #start sending lines from the testscript
        #get the data
        #check to see if the data is the same as in the refrence hdf5 file
        pass


def make_suite():
    suite = unittest.TestSuite()
    testcase = SystemTest('localhost', 8889)
    suite.addTest(testcase)
    return suite

if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(make_suite())
    sys.exit(not result.wasSuccessful())
