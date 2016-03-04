class ConfigField(object):

    """Represents a field of a field definition.

    The information held here spans the config, description and register files

    Attributes:
        name (str): The field name (e.g. OUTD)
        reg (list): The register string (e.g. ["3", "2", ">3"])
        cls (str): The field class (e.g. pos_out)
        cls_args (list): The arguments needed to configure the cls (e.g.
            ["encoder"])
        cls_extra (list): Any extra data associated with cls (e.g. enum values
            ["0  Falling", "1  Rising"])
        desc (str): The description of the field
    """

    def __init__(self, name, reg_lines, config_lines=None, desc_lines=None):
        """Initialise with relevant config/reg/desc lines for this field

        Args:
            reg_lines (list): Lines specifying field in registers file
            config_lines (list): Optional lines specifying field in config file
            desc_lines (list): Optional line specifying field in descriptions
            file
        """

        # parse reg_lines for name and reg info
        self.name = name
        assert len(reg_lines) == 1, \
            "Expected one reg line, got %s" % reg_lines
        reg_split = reg_lines[0].split()
        reg_name = reg_split[0]
        assert reg_name == self.name, \
            "Reg name %s != field name %s" % (reg_name, self.name)
        self.reg = reg_split[1:]

        # parse config_lines for name and cls*
        if config_lines:
            assert len(config_lines) >= 1, \
                "Expected at least one config line, got %s" % config_lines
            cls_split = config_lines[0].split()
            config_name = cls_split[0]
            self.cls = cls_split[1]
            self.cls_args = cls_split[2:]
            assert config_name == self.name, \
                "Config name %s != field name %s" % (config_name, self.name)
            # Any other lines are extra info, so just strip and retain
            self.cls_extra = [x.strip() for x in config_lines[1:]]
        else:
            self.cls = None
            self.cls_args = None
            self.cls_extra = None

        # Parse desc_lines for name and description
        if desc_lines:
            assert len(desc_lines) == 1, \
                "Expected one desc line got %s" % desc_lines
            desc_split = desc_lines[0].split(None, 1)
            assert desc_split[0] == self.name, \
                "Desc name %s != field name %s" % (desc_split[0], self.name)
            if len(desc_split) > 1:
                self.desc = desc_split[1].rstrip()
            else:
                self.desc = ""
        else:
            self.desc = None
