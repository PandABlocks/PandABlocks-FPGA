from collections import OrderedDict


class ConfigBlock(object):

    """Represents a block definition in the config file.

    Attributes:
        name (str): The block name (e.g. PULSE)
        num (int): The number of blocks that should be created (e.g. 2)
        base (int): The base register offset for this block
        desc (str): The description for this block
        fields (OrderedDict): map str field_name -> :class:`.ConfigField`
            instance for each field the block has
        registers (OrderedDict): map str attr_name -> (int reg num, ConfigField)
        outputs (OrderedDict): map str attr_name -> ([int out idx], ConfigField)

    Also, there will be an attribute for each attr_name in registers.keys()
    that also has that string as its value. This will allow lookup of register
    strings in a safe way. For example:

        self.TABLE_DATA = "TABLE_DATA"

    """

    def __init__(self, reg_line, config_line=None, desc_line=None):
        """Initialise with relevant config/reg/desc lines for this block.

        Should include block definition and all field definitions for this block

        Args:
            reg_line (str): Line specifying block in registers file
            config_line (str): Optional line specifying block in config file
            desc_line (str): Optional line specifying block in descriptions file
        """

        # parse reg_lines for name and base
        self.name, self.base = reg_line.split()
        self.base = int(self.base)

        if config_line:
            # parse config_lines for name and num
            if "[" in config_line:
                config_name, num = config_line.split("[")
                self.num = int(num.split("]")[0])
            else:
                config_name = config_line.strip()
                self.num = 1
            assert config_name == self.name, \
                "Config name %s != reg name %s" % (config_name, self.name)
        else:
            self.num = 1

        # parse desc_lines for descriptions
        if desc_line:
            desc_split = desc_line.split(None, 1)
            if len(desc_split) == 1:
                desc_name = desc_split[0]
                self.desc = ""
            else:
                desc_name, self.desc = desc_split
            assert desc_name == self.name, \
                "Desc name %s != reg name %s" % (desc_name, self.name)
        else:
            self.desc = None

        # setup the field and registers dicts
        self.fields = OrderedDict()
        self.registers = OrderedDict()
        self.outputs = OrderedDict()

    def add_field(self, field):
        """Add a ConfigField instance to self.fields dictionary

        This also sets an attribute on itself so we can do safer lookups. E.g.
        self.FORCE_RST = "FORCE_RST"

        Args:
            field (ConfigField): ConfigField instance
        """
        assert field.name not in self.fields, \
            "Field %s already part of block %s" % (field.name, self.name)
        self.fields[field.name] = field

        # List register attributes for each field
        attrs = []
        if field.cls and field.cls.endswith("_out"):
            # No registers for out, just set attribute
            setattr(self, field.name, field.name)
            indexes = [int(x) for x in field.reg[:self.num]]
            self.outputs[field.name] = (indexes, field)
        elif field.cls == "table":
            if field.reg[0] == "short":
                attrs.append(("%s_START" % field.name, field.reg[2]))
                attrs.append(("%s_DATA" % field.name, field.reg[3]))
                attrs.append(("%s_LENGTH" % field.name, field.reg[4]))
            else:
                attrs.append(("%s_ADDRESS" % field.name, field.reg[2]))
                attrs.append(("%s_LENGTH" % field.name, field.reg[3]))
        elif field.cls == "time":
            attrs.append(("%s_L" % field.name, field.reg[0]))
            attrs.append(("%s_H" % field.name, field.reg[1]))
        elif field.cls == "bit_mux":
            attrs.append((field.name, field.reg[0]))
            # Add a DLY register, but note that the logic for this is handled in
            # the controller, not in each block level simulation
            attrs.append(("%s_DLY" % field.name, field.reg[1]))
        elif field.reg[0] == "slow":
            attrs.append((field.name, field.reg[1]))
        else:
            attrs.append((field.name, field.reg[0]))

        # Create registers entries
        for name, reg in attrs:
            setattr(self, name, name)
            self.registers[name] = (int(reg), field)
