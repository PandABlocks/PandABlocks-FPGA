from collections import OrderedDict, namedtuple
import os

from .event import Event

config_dir = os.path.join(os.path.dirname(__file__), "..", "..", "config_d")


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
            val = val.strip()
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


class Block(object):

    def __init__(self, num):
        block_name = type(self).__name__.upper()
        regs = BlockRegisters.instances[block_name].fields
        self.reg_base = BlockRegisters.instances[block_name].base
        self.maxnum = BlockConfig.instances[block_name].num
        self.fields = BlockConfig.instances[block_name].fields
        assert num > 0 and num <= self.maxnum, \
            "Num %d out of range" % num
        self.num = num
        diff = set(regs) ^ set(self.fields)
        assert len(diff) == 0, "Mismatch %s" % diff

        # dict bus index -> name
        self.bit_outs, self.pos_outs = {}, {}
        # dict reg num -> name
        self.regs = {}
        # dict reg num -> lo/hi
        self.time_lohi = {}
        for name, field in self.fields.items():
            # Initialise the attribute value to 0
            setattr(self, name, 0)
            if field.cls.endswith("_out"):
                # outs are an array of bus indexes
                bus_index = int(regs[name].split()[self.num - 1])
                setattr(self, name, bus_index)
                if field.cls == "pos_out":
                    self.pos_outs[bus_index] = name
                else:
                    self.bit_outs[bus_index] = name
            elif field.cls == "table":
                # Tables are special...
                # TODO: handle tables
                # if "^" in val:
                #    val = pow(*map(int, val.split("^")))
                # else:
                #    val = int(val)
                self.regs["TABLE"] = name
            elif field.cls == "time":
                # Time values are "lo hi [>offset]"
                split = regs[name].split()
                reg_offset = [int(x) for x in split[:2]]
                self.regs[reg_offset[0]] = name
                self.time_lohi[reg_offset[0]] = "lo"
                self.regs[reg_offset[1]] = name
                self.time_lohi[reg_offset[1]] = "hi"
                # ignore offset as our blocks know about it
            else:
                # everything else is "reg_offset [filter]"
                split = regs[name].split(" ", 1)
                reg_offset = int(split[0])
                self.regs[reg_offset] = name

    def on_event(self, event):
        for name, value in event.reg.items():
            setattr(self, name, value)
        return Event()
