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
            self.num = None

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

        # setup the field dict
        self.fields = OrderedDict()

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
