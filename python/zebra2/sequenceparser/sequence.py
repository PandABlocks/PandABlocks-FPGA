#!/bin/env dls-python

from collections import OrderedDict

class Sequence(object):

    def __init__(self, name, mark=False):
        # These are {ts: {name: new_val}}
        self.name = name
        self.mark = mark
        self.inputs = OrderedDict()
        self.outputs = OrderedDict()

    def add_line(self, ts, inputs, outputs):
        assert ts not in self.inputs, \
            "Redefined ts %s" % ts
        if self.inputs:
            assert ts > self.inputs.keys()[-1], \
                "ts %s goes backwards" % ts
        self.inputs[ts] = inputs
        self.outputs[ts] = outputs

    def extend_line(self, inputs, outputs):
        ts = self.inputs.keys()[-1]
        self.inputs[ts].update(inputs)
        self.outputs[ts].update(outputs)
