# Support for xadc readout

# This file is loaded by the extension server

import os.path

XADC_PATH = '/sys/devices/soc0/amba/f8007100.adc/iio:device0'

class XADC:
    def __init__(self, node):
        self.node = node
        try:
            self.offset = self.read_node('offset')
        except:
            self.offset = 0
        self.scale = self.read_node('scale')

    def read_node(self, part):
        filename = os.path.join(XADC_PATH, '%s_%s' % (self.node, part))
        return float(file(filename).read())

    def read(self, number):
        return self.scale * (self.offset + self.read_node('raw'))


def parse(rw, node):
    return XADC(node)
