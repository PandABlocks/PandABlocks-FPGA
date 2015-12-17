from collections import OrderedDict


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
        # make a sequence for all
        all = Sequence("All")
        ts_off = 0
        for seq in self.sequences:
            changes = {}
            for ts in seq.inputs:
                all.add_line(ts_off+ts, seq.inputs[ts], seq.outputs[ts])
                changes.update(seq.inputs[ts])
                for k, v in seq.outputs[ts].items():
                    if k in changes:
                        changes[k] = v
            # now set them all back
            changes = dict((k, 0) for k,v in changes.items() if v != 0)
            all.add_line(ts_off + ts + 1, changes, {})
            # now wait for a bit
            ts_off += ts + 10
        self.sequences.append(all)

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
