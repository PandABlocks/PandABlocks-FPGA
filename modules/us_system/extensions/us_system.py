# Support for sysmon readout

# This file is loaded by the extension server

import os.path

SYSMON_PATH = '/sys/bus/iio/devices/iio:device0'


class SYSMON:
    def __init__(self, node):
        self.node = node
        try:
            self.offset = self.read_node('offset')
        except:
            self.offset = 0
        self.scale = self.read_node('scale')

    def read_node(self, part):
        filename = os.path.join(SYSMON_PATH, '%s_%s' % (self.node, part))
        return float(open(filename).read())

    def read(self, number):
        return self.scale * (self.offset + self.read_node('raw'))


class Extension:
    def __init__(self, count):
        assert count == 1, 'Only one system block expected'

    def parse_read(self, node):
        return SYSMON(node).read
