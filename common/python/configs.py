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
        # Block names should be UPPER_CASE_NO_NUMBERS
        assert re.match("[A-Z][A-Z_]*$", name), \
            "Expected BLOCK_NAME with no numbers, got %r" % name
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
        self.fields = FieldConfig.from_ini(ini, number)

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

    def filter_fields(self, regex):
        # type: (str) -> Iterable[FieldConfig]
        """Filter our child fields by typ"""
        regex = re.compile(regex + '$')
        for field in self.fields:
            if regex.match(field.type):
                yield field


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

    def __init__(self, name, number, type, description, **extra_config):
        # type: (str, int, str, str) -> None
        # Field names should be UPPER_CASE_OR_NUMBERS
        assert re.match("[A-Z][0-9A-Z_]*$", name), \
            "Expected FIELD_NAME, got %r" % name
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
        #: All the other extra config items
        self.extra_config = extra_config
        #: The current value of this field for simulation
        self.value = 0

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        """Create registers from the given base address, returning the next
        unused address"""
        raise NotImplementedError()

    def extra_config_lines(self):
        # type: () -> Iterable[str]
        """Produce any extra config lines from self.kwargs"""
        assert not self.extra_config, \
            "Can't handle extra config items %s" % self.extra_config
        return iter(())

    def address_line(self):
        # type: () -> str
        """Produce the line that should go in the registers file after name"""
        if self.registers:
            assert not self.bus_entries, \
                "Field %s type %s has both registers and bus entries" % (
                    self.name, self.type)
            registers_str = " ".join(str(r.number) for r in self.registers)
        else:
            registers_str = " ".join(str(e.index) for e in self.bus_entries)
        return registers_str

    @classmethod
    def lookup_subclass(cls, type):
        # Reverse these so we get ParamEnumFieldConfig (specific) before
        # its superclass ParamFieldConfig (catchall regex)
        for subclass in reversed(all_subclasses(cls)):
            if re.match(subclass.type_regex, type):
                return subclass

    @classmethod
    def from_ini(cls, ini, number):
        # type: (configparser.SafeConfigParser, int) -> List[FieldConfig]
        ret = []
        for section in ini.sections():
            if section != ".":
                d = dict(ini.items(section))
                subclass = FieldConfig.lookup_subclass(d["type"])
                assert subclass, "No FieldConfig for %r" % d["type"]
                try:
                    ret.append(subclass(section, number, **d))
                except TypeError as e:
                    raise TypeError(
                        "Cannot create FieldConfig from %s: %s" % (d, e))
        return ret

    def setter(self, block_simulation, v):
        if self.value != v:
            self.value = v
            if block_simulation.changes is None:
                block_simulation.changes = {}
            block_simulation.changes[self.name] = v

    def getter(self, block_simulation):
        return self.value

    def notify_changed(self, v):
        """Will be overwritten by simulation"""
        pass


class BitOutFieldConfig(FieldConfig):
    """These fields represent a single entry on the bit bus"""
    type_regex = "bit_out"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        for _ in range(self.number):
            self.bus_entries.append(BusEntryConfig("bit", bit_i))
            bit_i += 1
        return field_address, bit_i, pos_i, ext_i


class PosOutFieldConfig(FieldConfig):
    """These fields represent a position output"""
    type_regex = "pos_out"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        for _ in range(self.number):
            self.bus_entries.append(BusEntryConfig("pos", pos_i))
            pos_i += 1

        return field_address, bit_i, pos_i, ext_i


class ParamFieldConfig(FieldConfig):
    """These fields represent all other set/get parameters backed with a single
    register"""
    type_regex = "(param|read|write).*"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        self.registers.append(RegisterConfig(self.name, field_address))
        field_address += 1
        return field_address, bit_i, pos_i, ext_i


class ParamEnumFieldConfig(ParamFieldConfig):
    """A special These fields represent all other set/get parameters backed with
     a single register"""
    type_regex = "(param enum|read enum)"

    def extra_config_lines(self):
        # type: () -> Iterable[str]
        for k, v in sorted(self.extra_config.items()):
            assert k.isdigit(), "Only expecting integer enum entries in %s" % (
                self.extra_config,)
            if self.type.split()[0] != "read":
                # Read enums can be anything, but write and params should
                # be lower_case_or_numbers
                assert re.match("[a-z][0-9a-z_]*$", v), \
                    "Expected enum_value, got %r" % v
            yield "%s %s" % (pad(k, spaces=3), v)


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


class PosMuxFieldConfig(FieldConfig):
    """The fields represent a position input multiplexer selection"""
    type_regex = "pos_mux"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        self.registers.append(RegisterConfig(self.name, field_address))
        field_address += 1
        return field_address, bit_i, pos_i, ext_i


class TimeFieldConfig(FieldConfig):
    """The fields represent a configurable timer parameter """
    type_regex = "time"

    def register_addresses(self, field_address, bit_i, pos_i, ext_i):
        # type: (int, int, int, int) -> Tuple[int, int, int, int]
        self.registers.append(RegisterConfig(self.name, field_address))
        field_address += 1
        return field_address, bit_i, pos_i, ext_i
