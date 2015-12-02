from collections import OrderedDict


class SequenceParser(object):

    def __init__(self, f):
        lines = open(f).readlines()
        self.sequences = []
        for line in lines:
            if line.startswith("$"):
                name = line[1:].strip()
                self.sequences.append(Sequence(name))
            elif not line.startswith("#"):
                try:
                    self.parse_line(line)
                except Exception, e:
                    raise ValueError(e.message + "\nLine: %s" % line)

    def parse_line(self, line):
        line = line.strip()
        if line:
            split = line.split(":")
            ts = int(split[0].strip())
            inputs = self.parse_dict(split[1])
            if len(split) > 2:
                outputs = self.parse_dict(split[2])
            else:
                outputs = {}
            self.sequences[-1].add_line(ts, inputs, outputs)

    def parse_dict(self, s):
        d = {}
        s = s.strip()
        if s:
            for t in s.split(","):
                t = t.strip()
                k, v = t.split("=")
                d[k.strip()] = int(v.strip())
        return d


class Sequence(object):

    def __init__(self, name):
        # These are {ts: {name: new_val}}
        self.name = name
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

# test
if __name__ == "__main__":
    import os
    pulse = os.path.join(os.path.dirname(__file__), "pulse.seq")
    parser = SequenceParser(pulse)
    assert len(parser.sequences) == 2
    s = parser.sequences[0]
    assert len(s.inputs) == 5
    assert len(s.outputs) == 5
    print s.inputs.keys()
    print s.inputs.values()
    print s.outputs.values()
