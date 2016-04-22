from collections import OrderedDict
from logging import warning
import os

from configblock import ConfigBlock
from configfield import ConfigField


class ConfigParser(object):

    """Parser for config/register/description file

    Will populate itself with the blocks and fields described in the config
    files, checking for validity

    Attributes:
        blocks (OrderedDict): map str block_name -> :class:`.ConfigBlock`
            instance where block name doesn't include number (e.g. "SEQ")
        bit_bus (OrderedDict): map str block_name.field_name -> int bit_bus_idx
            for each block and field
        pos_bus (OrderedDict): map str block_name.field_name -> int pos_bus_idx
            for each block and field
        ext_names (OrderedDict): map int ext_bus_idx -> str
            block_name.field_name for each block and field
    """

    def __init__(self, config_dir):
        """Populate parser with files from config_dir

        Args:
            config_dir (str): Path to config directory
        """
        self.config_dir = config_dir
        self.blocks = OrderedDict()
        self.bit_bus = OrderedDict()
        self.pos_bus = OrderedDict()
        self.ext_names = OrderedDict()
        self.parse()

    def parse(self):
        # these are the temp dicts of blocks for each file
        sections = {}
        fnames = ["config", "registers", "description"]
        for fname in fnames:
            # dict block_name -> (block_line, field_dict)
            blocks = OrderedDict()
            sections[fname] = blocks
            # reversed lines from the file
            lines = self._read_lines(fname)
            # parse for a block definition in each set of lines
            while lines:
                block_data = self._parse_block(lines)
                if block_data:
                    blocks[block_data[0]] = block_data[1:]

        # sets of block names for each section
        config = sections["config"]
        reg = sections["registers"]
        desc = sections["description"]
        # Exclude blocks starting with * from checks
        config_set = set([b for b in sections["config"] if b[0] != '*'])
        reg_set = set(reg)
        desc_set = set(desc)
        all_set = config_set | reg_set | desc_set

        # need a registers section for each block
        assert reg_set == all_set, \
            "Missing block sections in registers: %s" \
            % sorted(all_set - reg_set)

        # warnings for missing or extra blocks
        if config_set > desc_set:
            warning("Blocks not in description file: %s"
                    % sorted(config_set - desc_set))
        if desc_set > config_set:
            warning("Extra blocks in description file: %s"
                    % sorted(desc_set - config_set))

        # and for wrong block ordering
        self._warn_ordering(config, reg, desc, "of blocks")

        # now step through blocks
        for block_name in reg:
            self._make_block_config(block_name, reg, config, desc)

    def _make_block_config(self, block_name, reg, config, desc):
        reg_line, reg_fields = reg[block_name]
        args = {}

        # lookup fields in desc
        if block_name in desc:
            args["desc_line"], desc_fields = desc[block_name]
        else:
            desc_fields = {}

        # if block is in config, use its field list instead of registers
        if block_name in config:
            args["config_line"], config_fields = config[block_name]
            fields = config_fields.copy()
            # add in any of the register fields
            for field_name in reg_fields:
                if field_name not in fields:
                    fields[field_name] = None
        else:
            config_fields = {}
            fields = reg_fields

        # warn if fields are reordered
        self._warn_ordering(config_fields, reg_fields, desc_fields,
                            "of fields in %s" % block_name)
        block = ConfigBlock(reg_line, **args)
        self.blocks[block.name] = block
        # iterate through the fields
        for field_name in fields:
            args = {}
            assert field_name in reg_fields, \
                "%s.%s missing from reg file" % (block_name, field_name)
            args["reg_lines"] = reg_fields[field_name]
            assert field_name in config_fields or block_name[0] == '*', \
                "%s.%s missing from config file" % (block_name, field_name)
            if field_name in config_fields:
                args["config_lines"] = config_fields[field_name]
            if field_name in desc_fields:
                args["desc_lines"] = desc_fields[field_name]
            field = ConfigField(field_name, **args)
            block.add_field(field)
            # Add entry to bit bus or pos bus if it's there
            if field.cls and field.cls.endswith("_out"):
                for i in range(block.num):
                    self._add_bus_entry(block, i, field)

    def _add_bus_entry(self, block, i, field):
        if block.num == 1:
            bus_name = "%s.%s" % (block.name, field.name)
        else:
            bus_name = "%s%d.%s" % (block.name, i+1, field.name)
        if field.cls == "bit_out":
            # add a bus entry to the bit bus
            idx = int(field.reg[i])
            self.bit_bus[bus_name] = idx
        elif field.cls == "pos_out":
            # add a bus entry to the pos bus
            idx = int(field.reg[i])
            self.pos_bus[bus_name] = idx
            # add the corresponding entry to the ext names lookup
            self.ext_names[idx] = bus_name
            # If we have extended entries then add them
            # A reg line looks like 1 2 3 4 / 33 34 35 36
            # so index to get rid of the slash
            if len(field.reg) > block.num * 2 + 1:
                idx = int(field.reg[block.num + 1 + i])
                self.ext_names[idx] = bus_name + "_H"
        else:
            # an entry just in the ext bus
            idx = int(field.reg[0])
            self.ext_names[idx] = field.name
            if len(field.reg) > 2:
                # For time, looks like 62 / 63, so add both
                idx = int(field.reg[2])
                self.ext_names[idx] = field.name + "_H"

    def _warn_ordering(self, config, reg, desc, err):
        """Check ordering of overlapping subsets of 3 ordered dicts

        Arguments:
            config (OrderedDict): config dict of blocks or fields
            reg (OrderedDict): registers dict of blocks or fields
            desc (OrderedDict): descriptions dict of blocks or fields
            err (str): error string to be appended to warning
        """
        # warning for ordering mismatches
        dicts = (config, reg, desc)
        subset = set(config) & set(reg) & set(desc)
        orders = [[x for x in d if x in subset] for d in dicts]
        for i, (c, r, d) in enumerate(zip(*orders)):
            if not (c == r == d):
                warning("Different ordering %s. First error: \n"
                        "c=%s/r=%s/d=%s" % (err, c, r, d))
                break
        # warn for any extra fields in config or desc
        extra_config = set(config) - set(reg)
        if extra_config:
            warning("Extra config fields %s" % list(extra_config))
        extra_desc = set(desc) - set(reg)
        if extra_desc:
            warning("Extra desc fields %s" % list(extra_desc))

    def _read_lines(self, fname):
        """Read lines from file in config_dir

        Args:
            fname (str): name of the file, e.g. "config"
        """
        path = os.path.join(self.config_dir, fname)
        lines = open(path).readlines()
        lines.reverse()
        return lines

    def _parse_block(self, lines):
        """Pop a block definition line from list of lines

        Args:
            lines (list[str]): input lines, first line at end of list

        Returns:
            (str, str, dict): The block data in the form of
                (block_name, block_line, field_dict) where field_dict is
                a map of field_name -> field_lines
        """
        # strip off comments and blank lines
        while lines:
            strip = lines[-1].strip()
            if not strip or strip.startswith("#"):
                lines.pop()
            else:
                break
        if not lines:
            return

        # this should be a block line
        block_line = lines.pop().rstrip()
        assert not block_line[0].isspace(), \
            "Block line may not be indented: '%s'" % block_line
        block_name = block_line.split("[")[0].split()[0]

        # dict field_name -> field_lines
        fields = OrderedDict()
        field_indent = None
        field_lines = None
        while lines:
            line = lines[-1].rstrip()
            strip = line.lstrip()
            indent = len(line) - len(strip)
            if not strip or strip.startswith("#"):
                # ignore comments or blank lines
                lines.pop()
            elif indent < field_indent:
                # less indent means finish
                break
            elif field_indent is None or indent <= field_indent:
                # new indent or repeated indent means start of field
                field_indent = indent
                field_lines = [lines.pop().rstrip()]
                fields[strip.split()[0]] = field_lines
            else:
                # more indent means extra lines
                field_lines.append(lines.pop().rstrip())

        # run out of lines, return what we have
        return block_name, block_line, fields
