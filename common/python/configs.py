import re

import math

from .compat import TYPE_CHECKING, configparser
from .ini_util import ini_get

if TYPE_CHECKING:
    from typing import List, Iterable, Any, Dict


def pad(name, spaces=19):
    """Pad the right of a name with spaces until it is at least spaces long"""
    return name.ljust(spaces)


def all_subclasses(cls):
    """Recursively find all the subclasses of cls"""
    ret = []
    for subclass in cls.__subclasses__():
        ret += [x for x in [subclass] + all_subclasses(subclass)
                if x not in ret]
    return ret


# This class wraps a generate_app.RegisterCounter instance, hides the
# .new_block() method replacing it with a new_field() method.
class FieldCounter:
    MAX_FIELDS = 64

    def __init__(self, counters, block_name):
        self.counters = counters
        self.block_name = block_name
        self.field_count = 0

        # Expose the relevant counters methods
        self.new_bit = counters.new_bit
        self.new_pos = counters.new_pos
        self.new_ext = counters.new_ext

    def new_field(self):
        result = self.field_count
        assert result < self.MAX_FIELDS, \
            "Block %s overflowed number of fields"
        self.field_count += 1
        return result


class BlockConfig(object):
    """The config for a single Block"""
    def __init__(self, name, type, number, ini, module_name):
        # type: (str, str, int, configparser.SafeConfigParser) -> None
        # Block names should be UPPER_CASE_NO_TRAILING_NUMBERS
        assert re.match("[A-Z][0-9A-Z_]*[A-Z]$", name), \
            "Expected BLOCK_NAME with no trailing numbers, got %r" % name
        #: The name of the Block, like LUT
        self.name = name
        #: The number of instances Blocks that will be created, like 8
        self.number = number
        #: The Block section of the register address space
        self.block_address = None
        #: The module name (can be different to block name)
        self.module_name = module_name
        #: The VHDL entity name, like lut
        self.entity = ini.get(".", "entity")
        #: Is the block soft, sfp, fmc or dma?
        self.type = ini_get(ini, '.', 'type', type)
        #: Any constraints?
        self.constraints = ini_get(ini, '.', 'constraints', '').split()
        #: Does the block require IP?
        self.ip = ini_get(ini, '.', 'ip', '').split()
        self.otherconst = ini_get(ini, '.', 'otherconst', '')
        #: The description, like "Lookup table"
        self.description = ini.get(".", "description")
        # If extension required but not specified put entity name here
        self.extension = ini_get(ini, '.', 'extension', None)
        if self.extension == '':
            self.extension = self.entity
        #: All the child fields
        self.fields = FieldConfig.from_ini(ini, number)

    def register_addresses(self, block_counters):
        # type: (RegisterCounter) -> None
        """Register this block in the address space"""
        self.block_address = block_counters.new_block()
        counters = FieldCounter(block_counters, self.name)
        for field in self.fields:
            field.register_addresses(counters)

    def filter_fields(self, regex, matching=True):
        # type: (str, bool) -> Iterable[FieldConfig]
        """Filter our child fields by typ. If not matching return those
        that don't match"""
        regex = re.compile(regex + '$')
        for field in self.fields:
            is_a_match = bool(regex.match(field.type))
            # If matching and is_a_match or not matching and isnt_a_match
            # return the field
            if matching == is_a_match:
                yield field


class RegisterConfig(object):
    """A low level register name and number backing this field"""
    def __init__(self, name, number=-1, prefix='', extension=''):
        # type: (str, int, str) -> None
        #: The name of the register, like INPA_DLY
        self.name = name
        #: The register number relative to Block, like 9
        self.number = number
        # String to be written before the register
        self.prefix = prefix
        #: For an extension field, the register path
        self.extension = extension


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

    def __init__(self, name, number, type, description, wstb=False,
                 extension=None, extension_reg=None, **extra_config):
        # type: (str, int, str, str, bool, str, str) -> None
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
        #: If a write strobe is required, set wstb to 1
        self.wstb = wstb
        #: Store the extension register info
        self.extension = extension
        self.extension_reg = extension_reg
        #: The current value of this field for simulation
        self.value = 0
        #: All the other extra config items
        self.extra_config_lines = list(self.parse_extra_config(extra_config))

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> Iterable[str]
        """Produce any extra config lines from self.kwargs"""
        assert not extra_config, \
            "Can't handle extra config items %s" % extra_config
        return iter(())

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        """Create registers using the FieldCounter object"""
        raise NotImplementedError()

    def address_line(self):
        # type: () -> str
        """Produce the line that should go in the registers file after name"""
        def make_reg_name(r):
            result = []
            if r.prefix:
                result.append(r.prefix)
            if r.number >= 0:
                result.append(str(r.number))
            if r.extension:
                result.extend(['X', r.extension])
            return ' '.join(result)

        if self.registers:
            assert not self.bus_entries, \
                "Field %s type %s has both registers and bus entries" % (
                    self.name, self.type)
            registers_str = " ".join(make_reg_name(r) for r in self.registers)
        else:
            registers_str = " ".join(str(e.index) for e in self.bus_entries)
        return registers_str

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        return self.type

    def numbered_registers(self):
        # type: () -> List[RegisterConfig]
        """Filter self.registers, only producing registers with a number
        (not those that are purely extension registers)"""
        return [r for r in self.registers if r.number != -1]

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
                    raise TypeError( "Cannot create %s from %s: %s" % (
                        subclass.__name__, d, e))
        return ret

    def setter(self, block_simulation=0, v=0):
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

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig("bit", counters.new_bit()))


class PosOutFieldConfig(FieldConfig):
    """These fields represent a position output"""
    type_regex = "pos_out"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig("pos", counters.new_pos()))


class ExtOutFieldConfig(FieldConfig):
    """These fields represent a ext output"""
    type_regex = "ext_out"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig("ext", counters.new_ext()))


class ExtOutTimeFieldConfig(ExtOutFieldConfig):
    """These fields represent a ext output timestamp, which requires two
    registers"""
    type_regex = "ext_out timestamp"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.extend([
                BusEntryConfig("ext", counters.new_ext()),
                BusEntryConfig("ext", counters.new_ext())])


class TableFieldConfig(FieldConfig):
    """These fields represent a table field"""
    type_regex = "table"
    #: How many 32-bit words per line?
    words = None

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        self.registers.extend([
            RegisterConfig(self.name, prefix='long 2^8'),
            RegisterConfig(self.name + "_ADDRESS", counters.new_field()),
            RegisterConfig(self.name + "_LENGTH", counters.new_field())])

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        return "table %s" % self.words

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> Iterable[str]
        self.words = extra_config.pop("words", 1)
        for hibit, v in sorted(extra_config.items()):
            # Format is:
            # hibit:[lobit] name [type]
            #     desc
            #     [enums]
            lines = v.split("\n")
            # If first character of first line is a digit, it is lobit
            if lines[0][0].isdigit():
                lobit, name_and_type = lines[0].split(" ", 1)
                bits = "%s:%s" % (hibit, lobit)
            else:
                name_and_type = lines[0]
                bits = "%s:%s" % (hibit, hibit)
            yield "%s %s" % (pad(bits), name_and_type)
            name = name_and_type.split()[0]
            desc = lines[1]
            self.description += "\n        %s %s " % (pad(name), desc)
            # Enums have more lines
            for line in lines[2:]:
                yield "    %s" % line


class TableShortFieldConfig(TableFieldConfig):
    """These fields represent a table field"""
    type_regex = "table short"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        self.registers.extend([
            RegisterConfig(self.name, prefix='short 512'),
            RegisterConfig(self.name + "_START", counters.new_field()),
            RegisterConfig(self.name + "_DATA", counters.new_field()),
            RegisterConfig(self.name + "_LENGTH", counters.new_field())])


class ParamFieldConfig(FieldConfig):
    """These fields represent all other set/get parameters backed with a single
    register"""
    type_regex = "(param|read|write).*"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        if self.extension:
            if self.extension_reg is None:
                address = -1
            else:
                address = counters.new_field()
        else:
            address = counters.new_field()

        self.registers.append(
            RegisterConfig(self.name, address, extension=self.extension))


class EnumParamFieldConfig(ParamFieldConfig):
    """A special These fields represent all other set/get parameters backed with
     a single register"""
    type_regex = "(param|read) enum"

    #: If there is an enum, how long is it?
    enumlength = 0

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> Iterable[str]
        for k, v in sorted(extra_config.items()):
            assert k.isdigit(), "Only expecting integer enum entries in %s" % (
                extra_config,)
            yield "%s %s" % (pad(k, spaces=3), v)
            # Work out biggest enum value
            self.enumlength = max(self.enumlength, int(k))
        self.enumlength = int(math.ceil(math.log(self.enumlength + 1, 2)) - 1)


class BitMuxFieldConfig(FieldConfig):
    """These fields represent a single entry on the pos bus"""
    type_regex = "bit_mux"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        # One register for the mux value, one for a delay line
        self.registers.extend([
            RegisterConfig(self.name, counters.new_field()),
            RegisterConfig(self.name + "_dly", counters.new_field())])


class PosMuxFieldConfig(FieldConfig):
    """The fields represent a position input multiplexer selection"""
    type_regex = "pos_mux"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        self.registers.append(
            RegisterConfig(self.name, counters.new_field()))


class TimeFieldConfig(FieldConfig):
    """The fields represent a configurable timer parameter """
    type_regex = "time"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        # One register for the _L value and one for the _H value
        self.registers.extend([
            RegisterConfig(self.name + "_L", counters.new_field()),
            RegisterConfig(self.name + "_H", counters.new_field())])
