from ..configparser import ConfigParser


class Block(object):

    @classmethod
    def load_config(cls, config_dir):
        """Load the config def, then add properties to subclasses"""
        cls.parser = ConfigParser(config_dir)
        for subclass in cls.__subclasses__():
            subclass.add_properties()

    @classmethod
    def add_properties(cls):
        block_name = cls.__name__.upper()
        cls.config_block = cls.parser.blocks[block_name]
        # add a property that stores changes for outputs
        for name, field in cls.config_block.fields.items():
            cls.add_property(name)

    @classmethod
    def add_property(cls, attr):
        def setter(self, v):
            if getattr(self, attr) != v:
                if not hasattr(self, "_changes"):
                    self._changes = {}
                setattr(self, "_%s" % attr, v)
                self._changes[attr] = v
        def getter(self):
            return getattr(self, "_%s" % attr, 0)
        setattr(cls, attr, property(getter, setter))

    def on_event(self, ts, changes):
        for name, value in changes.items():
            setattr(self, name, value)
        return None

    def oldinit(self, num):
        block_name = type(self).__name__.upper()
        config_block = self.parser.blocks[block_name]
        self.reg_base = config_block.base
        self.maxnum = config_block.num
        self.fields = config_block.fields
        assert num > 0 and num <= self.maxnum, \
            "Num %d out of range" % num
        self.num = num

        # dict bus index -> name
        self.bit_outs, self.pos_outs = {}, {}
        # dict reg num -> name
        self.regs = {}
        # dict reg num -> lo/hi
        self.time_lohi = {}
        for name, field in self.fields.items():
            if field.cls.endswith("_out"):
                # outs are an array of bus indexes
                bus_index = int(field.reg[self.num - 1])
                setattr(self, name, bus_index)
                if field.cls == "pos_out":
                    self.pos_outs[bus_index] = name
                else:
                    self.bit_outs[bus_index] = name
            elif field.cls == "table":
                # Work out if table is short or long
                if len(field.reg) == 1:
                    # This is a long table
                    # "table_len"
                    setattr(self, name, 0)
                    # TODO: handle tables
                    # if "^" in val:
                    #    val = pow(*map(int, val.split("^")))
                    # else:
                    #    val = int(val)
                elif len(field.reg) == 3:
                    # This is a short table
                    # "table_len rst_reg data_reg"
                    setattr(self, name + "_RST", 0)
                    setattr(self, name + "_DATA", 0)
                    setattr(self, name + "_WSTB", 0)
                self.regs["TABLE"] = name
            elif field.cls == "time":
                # Initialise the attribute value to 0
                setattr(self, name, 0)
                # Time values are "lo hi [>offset]"
                reg_offset = [int(x) for x in field.reg[:2]]
                self.regs[reg_offset[0]] = name
                self.time_lohi[reg_offset[0]] = "lo"
                self.regs[reg_offset[1]] = name
                self.time_lohi[reg_offset[1]] = "hi"
                # ignore offset as our blocks know about it
            elif field.cls == "software":
                pass
            else:
                # Initialise the attribute value to 0
                setattr(self, name, 0)
                # everything else is "reg_offset [filter]"
                if field.reg[0] == "slow":
                    reg_offset = int(field.reg[1])
                else:
                    reg_offset = int(field.reg[0])
                self.regs[reg_offset] = name

