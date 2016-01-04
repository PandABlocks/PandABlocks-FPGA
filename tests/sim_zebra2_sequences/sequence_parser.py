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

def generate_fpga_sequences(fname):
    parser = SequenceParser(fname)
    ts_off = 0
    for sequence in parser.sequences:
        # if we were successful, then write the "All" test to FPGA
        if self.sequence.name == "All":
            # Get the column headings
            bus_in = []
            bus_out = []
            reg_in = []
            reg_out = []

            current = {}
            for name, field in block.fields.items():
                if field.typ.endswith("_mux"):
                    bus_in.append(name)
                elif field.cls.endswith("_out"):
                    bus_out.append(name)
                elif field.cls == "read":
                    reg_out.append(name)
                else:
                    reg_in.append(name)
            # Write the lines
            try:
                os.makedirs(fpga_dir)
            except OSError:
                pass
            fbus_in = open(
                os.path.join(fpga_dir, self.block + "_bus_in.txt"), "w")
            fbus_out = open(
                os.path.join(fpga_dir, self.block + "_bus_out.txt"), "w")
            freg_in = open(
                os.path.join(fpga_dir, self.block + "_reg_in.txt"), "w")
            freg_out = open(
                os.path.join(fpga_dir, self.block + "_reg_out.txt"), "w")
            fbus_in.write("\t".join(["TS"] + bus_in) + "\n")
            fbus_out.write("\t".join(["TS"] + bus_out) + "\n")
            freg_in.write("\t".join(["TS"] + reg_in) + "\n")
            freg_out.write("\t".join(["TS"] + reg_out) + "\n")
            for ts in self.sequence.inputs:
                current.update(self.sequence.inputs[ts])
                current.update(self.sequence.outputs[ts])

                lbus_in = [str(current.get(name, 0)) for name in bus_in]
                lbus_out = [str(current.get(name, 0)) for name in bus_out]
                lreg_in = [str(current.get(name, 0)) for name in reg_in]
                lreg_out = [str(current.get(name, 0)) for name in reg_out]

                fbus_in.write("\t".join([str(ts)] + lbus_in) + "\n")
                fbus_out.write("\t".join([str(ts+1)] + lbus_out) + "\n")
                freg_in.write("\t".join([str(ts)] + lreg_in) + "\n")
                freg_out.write("\t".join([str(ts+1)] + lreg_out) + "\n")

            fbus_in.close()
            fbus_out.close()
            freg_in.close()
            freg_out.close()

# test
if __name__ == "__main__":
    import os
    import sys
    fname = os.path.join(os.path.dirname(__file__), sys.argv[1] + ".seq")
    generate_fpga_sequences(fname)
