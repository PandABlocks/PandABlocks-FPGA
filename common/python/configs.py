import re

from .compat import TYPE_CHECKING, configparser

if TYPE_CHECKING:
    from typing import List, Iterable, Tuple, Dict


# Max number of FPGA registers in a block
MAX_REG = 64


def pad(name, spaces=15):
    """Pad the right of a name with spaces until it is at least spaces long"""
    return name.ljust(spaces)


def all_subclasses(cls):
    """Recursively find all the subclasses of cls"""
    ret = []
    for subclass in cls.__subclasses__():
        ret += [x for x in [subclass] + all_subclasses(subclass)
                if x not in ret]
    return ret


class BlockConfig(object):
    """The config for a single Block"""
    def __init__(self, name, number, ini):
        # type: (str, int, configparser.SafeConfigParser) -> None
        #: The name of the Block, like LUT
        self.name = name
        #: The number of instances Blocks that will be created, like 8
        self.number = number
        #: The Block section of the register address space
        self.block_address = None
        #: The VHDL entity name, like lut
        self.entity = ini.get(".", "entity")
        #: The description, like "Lookup table"
        self.description = ini.get(".", "description")
        #: All the child fields
        self.fields = []  # type: List[FieldConfig]
        for section in ini.sections():
            if section != ".":
                d = dict(ini.items(section))
                try:
                    field = FieldConfig.from_dict(section, number, d)
                except TypeError as e:
                    raise TypeError("Cannot create FieldConfig from %s: %s" % (
                        d, e))
                self.fields.append(field)

    def register_addresses(self, block_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        """Register this block in the address space"""
        field_address = 0
        for field in self.fields:
            field_address, bit_i, pos_i, ext_i = field.register_addresses(
                field_address, bit_i, pos_i, ext_i)
            assert field_address < MAX_REG, \
                "Block %s field %s overflowed %s registers" % (
                    self.name, field.name, MAX_REG)
        self.block_address = block_address
        block_address += 1
        return block_address, bit_i, pos_i, ext_i

    def filter_fields(self, wildcard_type):
        # type: (str) -> Iterable[FieldConfig]
        """Filter our child fields by typ"""
        regex = re.compile(wildcard_type.replace("*", ".*"))
        for field in self.fields:
            if regex.match(field.type):
                yield field

    def config_lines(self):
        # type: () -> Iterable[str]
        """Produce the lines that should go in the config file, not newline
        terminated"""
        yield "%s[%s]" % (self.name, self.number)
        for field in self.fields:
            for line in field.config_lines():
                yield "    %s" % line

    def registers_lines(self):
        """Produce the lines that should go in the registers file, not newline
        terminated"""
        yield "%s %s" % (pad(self.name), self.block_address)
        for field in self.fields:
            for line in field.registers_lines():
                yield "    %s" % line

    def descriptions_lines(self):
        """Produce the lines that should go in the descriptions file, not
        newline terminated"""
        yield "%s %s" % (pad(self.name), self.description)
        for field in self.fields:
            for line in field.descriptions_lines():
                yield "    %s" % line


class RegisterConfig(object):
    """A low level register name and number backing this field"""
    def __init__(self, name, number):
        # type: (str, int) -> None
        #: The name of the register, like INPA_DLY
        self.name = name
        #: The register number relative to Block, like 9
        self.number = number


class BusEntryConfig(object):
    """A bus entry belonging to a field"""
    def __init__(self, bus, index):
        # type: (str, int) -> None
        #: The name of the register, like bit
        self.bus = bus
        #: The bus index, like 5
        self.index = index


class FieldConfig(object):
    """The config for a single Field of a Block"""
    #: Regex for matching a type string to this field
    type_regex = None

    def __init__(self, name, number, type, description, **kwargs):
        # type: (str, int, str, str) -> None
        #: The name of the field relative to it's Block, like INPA
        self.name = name
        #: The number of instances Blocks that will be created, like 8
        self.number = number
        #: The complete type string, like param lut
        self.type = type
        #: The long description of the field
        self.description = description
        #: The list of registers this field uses
        self.registers = []  # type: List[RegisterConfig]
        #: The list of bus entries this field has
        self.bus_entries = []  # type: List[BusEntryConfig]
        # All the other kwargs
        self.kwargs = kwargs

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        """Create registers from the given base address, returning the next
        unused address"""
        raise NotImplementedError()

    def config_lines(self):
        # type: () -> Iterable[str]
        """Produce the lines that should go in the config file, not indented
        or newline terminated"""
        yield "%s %s" % (pad(self.name), self.type)

    def registers_lines(self):
        """Produce the lines that should go in the registers file, not indented
        or newline terminated"""
        if self.registers:
            assert not self.bus_entries, \
                "Field %s type %s has both registers and bus entries" % (
                    self.name, self.type)
            registers_str = " ".join(str(r.number) for r in self.registers)
        else:
            registers_str = " ".join(str(e.index) for e in self.bus_entries)
        yield "%s %s" % (pad(self.name), registers_str)

    def descriptions_lines(self):
        """Produce the lines that should go in the descriptions file, not
        indented or newline terminated"""
        yield "%s %s" % (pad(self.name), self.description)

    @classmethod
    def from_dict(cls, name, number, d):
        # type: (str, int, Dict[str, str]) -> FieldConfig
        type = d["type"]
        # Reverse these so we get ParamEnumFieldConfig (specific) before its
        # superclass ParamFieldConfig (catchall regex)
        for subclass in reversed(all_subclasses(FieldConfig)):
            if re.match(subclass.type_regex, type):
                return subclass(name, number, **d)


class BitOutFieldConfig(FieldConfig):
    """These fields represent a single entry on the bit bus"""
    type_regex = "bit_out"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        for _ in range(self.number):
            self.bus_entries.append(BusEntryConfig("bit", bit_i))
            bit_i += 1
        return field_address, bit_i, pos_i, ext_i


class ParamFieldConfig(FieldConfig):
    """These fields represent all other set/get parameters backed with a single
    register"""
    type_regex = "param.*"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        self.registers.append(RegisterConfig(self.name, field_address))
        field_address += 1
        return field_address, bit_i, pos_i, ext_i


class ParamEnumFieldConfig(ParamFieldConfig):
    """A special These fields represent all other set/get parameters backed with a single
    register"""
    type_regex = "param enum"

    def config_lines(self):
        for line in super(ParamEnumFieldConfig, self).config_lines():
            yield line
        for k, v in sorted(self.kwargs.items()):
            assert k.isdigit(), "Only expecting integer enum entries in %s" % (
                self.kwargs,)
            yield "    %s %s" % (pad(k, spaces=3), v)


class BitMuxFieldConfig(FieldConfig):
    """These fields represent a single entry on the pos bus"""
    type_regex = "bit_mux"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        # One register for the mux value, one for a delay line
        self.registers.append(RegisterConfig(self.name, field_address))
        field_address += 1
        self.registers.append(RegisterConfig(self.name + "_dly", field_address))
        field_address += 1
        return field_address, bit_i, pos_i, ext_i

