import os
from collections import OrderedDict, namedtuple


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


def populate_registers(config_dir):
    fname = os.path.join(config_dir, "registers")
    instance = None
    for line in open(fname).readlines():
        empty = line.strip() == ""
        if empty or line.strip().startswith("#"):
            pass
        elif line.startswith(" "):
            name, val = line.strip().split(" ", 1)
            val = val.strip()
            instance.add_field(name.strip(), val)
        else:
            name, base = line.strip().split()
            instance = BlockRegisters(name, int(base))
    return BlockRegisters.instances


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


def populate_config(config_dir):
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
                typ = ""
            instance.add_field(name, cls, typ)
        else:
            if "[" in line:
                name, num = line.split("[")
                num = num.split("]")[0]
            else:
                name = line
                num = 1
            instance = BlockConfig(name.strip(), int(num))
    return BlockConfig.instances


def load_config(config_dir):
    registers = populate_registers(config_dir)
    config = populate_config(config_dir)
    return (registers, config)
