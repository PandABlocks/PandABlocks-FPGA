#!/bin/env python

import sys
import os

from zebra2.sequenceparser.sequence import Sequence

class SequenceParser(object):

    def __init__(self, f):
        lines = open(f).readlines()
        self.sequences = []
        for line in lines:
            if line.startswith("$"):
                name = line[1:].strip()
                if name.startswith("!"):
                    mark = True
                    name = name[1:].strip()
                else:
                    mark = False
                self.sequences.append(Sequence(name, mark))
            elif not line.startswith("#"):
                try:
                    self.parse_line(line)
                except Exception, e:
                    raise ValueError(e.message + "\nLine: %s" % line)

    def parse_line(self, line):
        line = line.strip()
        if line:
            split = line.split(":")
            inputs = self.parse_dict(split[1])
            if len(split) > 2:
                outputs = self.parse_dict(split[2])
            else:
                outputs = {}

            ts = split[0].strip()
            seq = self.sequences[-1]
            if ts:
                seq.add_line(int(ts), inputs, outputs)
            else:
                seq.extend_line(inputs, outputs)

    def parse_dict(self, s):
        d = {}
        s = s.strip()
        if s:
            for t in s.split(","):
                t = t.strip()
                k, v = t.split("=")
                # detect 0x prefix automatically
                if k == "TABLE_ADDRESS":
                    d[k.strip()] = v.strip()
                else:
                    d[k.strip()] = int(v.strip(), 0)
        return d


# test
if __name__ == "__main__":
    # sequence file for block
    block = sys.argv[1]
    # parse sequence
    fname = os.path.join(os.path.dirname(__file__), block + ".seq")
    parser = SequenceParser(fname)
