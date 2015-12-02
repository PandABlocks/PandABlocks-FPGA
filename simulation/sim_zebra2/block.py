from collections import OrderedDict, namedtuple
import os

config_dir = os.path.join(os.path.dirname(__file__), "..", "..", "config")


class BlockRegisters(object):
    instances = OrderedDict()

    def __init__(self, name, base):
        self.name = name
        self.base = base
        self.fields = OrderedDict()
        self.instances[name] = self

    def add_field(self, name, val):
        assert name not in self.fields, \
            "Already have register %s" % name
        self.fields[name] = val


@apply
def populate_registers():
    fname = os.path.join(config_dir, "registers")
    instance = None
    for line in open(fname).readlines():
        empty = line.strip() == ""
        if empty or line.startswith("#"):
            pass
        elif line.startswith(" "):
            name, val = line.strip().split(" ", 1)
            val = val.strip().split()
            if len(val) == 1:
                val = int(val[0])
            else:
                val = [int(v) for v in val]
            instance.add_field(name.strip(), val)
        else:
            name, base = line.strip().split()
            instance = BlockRegisters(name, int(base))

Field = namedtuple("Field", "cls typ")


class BlockConfig(object):
    instances = OrderedDict()

    def __init__(self, name, num):
        self.name = name
        self.num = num
        self.fields = OrderedDict()
        self.instances[name] = self

    def add_field(self, name, cls, typ):
        assert name not in self.fields, \
            "Field %s already exists" % name
        self.fields[name] = Field(cls, typ)


@apply
def populate_config():
    fname = os.path.join(config_dir, "config")
    instance = None
    for line in open(fname).readlines():
        empty = line.strip() == ""
        if empty or line.startswith("#") or line.startswith("     "):
            pass
        elif line.startswith(" "):
            split = line.strip().split()
            name = split[0].strip()
            cls = split[1].strip()
            if len(split) > 2:
                typ = split[2].strip()
            else:
                typ = None
            instance.add_field(name, cls, typ)
        else:
            if "[" in line:
                name, num = line.split("[")
                num = num.split("]")[0]
            else:
                name = line
                num = 1
            instance = BlockConfig(name.strip(), int(num))


class Block(object):

    def __init__(self, num):
        name = type(self).__name__.upper()
        self.regs = BlockRegisters.instances[name].fields
        self.maxnum = BlockConfig.instances[name].num
        self.fields = BlockConfig.instances[name].fields
        assert num > 0 and num <= self.maxnum, \
            "Num %d out of range" % num
        self.num = num
        diff = set(self.regs) ^ set(self.fields)
        assert len(diff) == 0, "Mismatch %s" % diff
        for name, value in self.regs.items():
            if isinstance(value, list):
                value = value[self.num]
            setattr(self, name, value)

    def on_event(self, event):
        # will give us an event object with a timeStamp object and the
        # changes in its input signals
        raise NotImplementedError
        # return an event object with a timeStamp object and the changes
        # in its output signals
