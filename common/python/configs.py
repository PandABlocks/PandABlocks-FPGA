import os
import re
from collections import OrderedDict

from .compat import TYPE_CHECKING, configparser
from .ini_util import ini_get, read_ini

if TYPE_CHECKING:
    from typing import List, Iterable, Any, Dict, Optional


ROOT = os.path.join(os.path.dirname(__file__), "..", "..")


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


def allocate(self, counter, limit, name):
    result = getattr(self, counter)
    assert result < limit, "Overflowed %s" % name
    setattr(self, counter, result + 1)
    return result


# This class generates unique register numbers.  It is designed to be passed to
# the implement_blocks() and register_addresses() functions.  Methods are
# provided for generating new block, bit, pos, ext addresses.
class RegisterCounter:
    # Max number of Block types
    MAX_BLOCKS = 32

    # Max size of buses
    MAX_BIT = 128
    MAX_POS = 32
    MAX_EXT = 32

    def __init__(self, block_count=0, bit_count=0, pos_count=0, ext_count=0):
        self.block_count = block_count
        self.bit_count = bit_count
        self.pos_count = pos_count
        self.ext_count = ext_count

    def new_block(self):
        return allocate(self, 'block_count', self.MAX_BLOCKS, 'block addresses')

    def new_bit(self):
        return allocate(self, 'bit_count', self.MAX_BIT, 'bit bus entries')

    def new_pos(self):
        return allocate(self, 'pos_count', self.MAX_POS, 'pos bus entries')

    def new_ext(self):
        return allocate(self, 'ext_count', self.MAX_EXT, 'ext bus entries')


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
        return allocate(self, "field_count", self.MAX_FIELDS, 'number of fields')


class BlockConfig(object):
    """The config for a single Block"""
    def __init__(self, name, type, number, ini_path, site=(None, None, None)):
        # type: (str, str, int, str, Optional[int]) -> None
        # Block names should be UPPER_CASE_NO_TRAILING_NUMBERS
        assert re.match("[A-Z][0-9A-Z_]*[A-Z]$", name), \
            "Expected BLOCK_NAME with no trailing numbers, got %r" % name
        ini = read_ini(os.path.join(ROOT, ini_path))
        #: The name of the Block, like LUT
        self.name = name
        #: The number of instances Blocks that will be created, like 8
        self.number = number
        #: The path to the module that holds this block ini
        self.module_path = os.path.dirname(ini_path)
        #: The path to the ini file for this Block, relative to ROOT
        self.ini_path = ini_path
        #: The Block section of the register address space
        self.block_address = None
        #: If the type == sfp, which site number
        self.site_config(site)
        #: The VHDL entity name, like lut
        self.entity = ini.get(".", "entity")
        #: Is the block soft, sfp, fmc or dma?
        self.type = ini_get(ini, '.', 'type', type)
        #: What type is the sfp/fmc interface?
        interfaces = ini_get(ini, '.', 'interfaces', '').split()
        self.interfaces = self.combineSiteInterfaces(interfaces)
        #: Any constraints?
        self.constraints = ini_get(ini, '.', 'constraints', '').split()
        #: Does the block require IP?
        self.ip = ini_get(ini, '.', 'ip', '').split()
        self.otherconst = ini_get(ini, '.', 'otherconst', '')
        if (self.otherconst == "mgt_pins"):
            #: Interfaces need MGT pins constraints
            self.generateInterfaceConstraints()
        #: The description, like "Lookup table"
        self.description = ini.get(".", "description")
        # If extension required but not specified put entity name here
        self.extension = ini_get(ini, '.', 'extension', None)
        if self.extension == '':
            self.extension = self.entity
        self.extra_sites = ini_get(ini, '.', 'extra_interface', None)
        #: All the child fields
        self.fields = FieldConfig.from_ini(
            ini, number)  # type: List[FieldConfig]
        #: List of Extension fields in the block
        self.calc_extensions = []
        #: Are there any suffixes?
        self.block_suffixes = ini_get(ini, '.', 'block_suffixes', '').split()

    def site_config(self, site_tuple):

        siteName, siteType, siteNumber = site_tuple
        if siteName:
            if siteNumber.isdigit():
                self.site = siteName + '.' + siteType + '_ARR(' + \
                            str(int(siteNumber)-1) + ')'
                self.site_LOC = (siteName + siteNumber).upper()
            else:
                self.site = siteNumber
                self.site_LOC = siteNumber
        else:
            self.site = None
            self.site_LOC = None

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

    def combineSiteInterfaces(self, interfaces):
        # type: (List(str)) -> list[tuple]
        # If a site is defined modify the interfaces to include the site number
        combinedInterfaces = []  # type: List[tuple]
        for interface in interfaces:
            if self.site:
                # site_number=re.findall(r'\d+', self.site)[0]
                combinedInterface = (interface, self.site)
            else:
                site = interface + '.' + interface + "_ARR(0)"
                combinedInterface = (interface, site)
            combinedInterfaces.append(combinedInterface)
        return combinedInterfaces

    def generateInterfaceConstraints(self):
        """Generate MGT Pints constraints"""
        self.interfaceConstraints = []
        # Find a way not to hard code this...
        if "FMC" in self.site_LOC:
            constraint = "FMC" + "_MGT_pins.xdc"
        else:
            constraint = self.site_LOC + "_MGT_pins.xdc"
        if constraint not in self.interfaceConstraints:
            self.interfaceConstraints.append(constraint)

    def generate_calc_extensions(self):
        # Iterate through the fields and add any with writeExtension type to the list
        for field in self.filter_fields("extension_.*"):
            extension = (field.name, field.registers[0].number)
            if not self.extension: 
                self.extension = self.name.lower()
            self.calc_extensions.append(extension)
        # After extensions have been added to self.read_extensions/self.write_extensions
        # Iterate through the fields, when a writeExtension is specified find its number
        for field in self.fields:
            for calc_extension, num in self.calc_extensions:
                for extension in field.extension_write.split(" "):
                     if calc_extension == extension:
                        field.extension_nums.append([num, "write"])
                for extension in field.extension_read.split(" "):
                    if calc_extension == extension:
                        field.extension_nums.append([num, "read"])

def make_getter_setter(config):
    def getter(self):
        return getattr(self, "_" + config.name, 0)

    def setter(self, v):
        if getter(self) != v:
            if self.changes is None:
                self.changes = {}
            self.changes[config.name] = v
            setattr(self, "_" + config.name, v)

    # Add the reference to config so we can get it in BlockSimulationMeta
    getter.config = config
    return getter, setter


class RegisterConfig(object):
    """A low level register name and number backing this field"""
    def __init__(self, name, number=-1, prefix='', extension='', write_extension='', read_extension=''):
        # type: (str, int, str, str, str, str) -> None
        #: The name of the register, like INPA_DLY
        self.name = name.replace('.', '_')
        #: The register number relative to Block, like 9
        self.number = number
        # String to be written before the register
        self.prefix = prefix
        #: For an extension field, the register path
        self.extension = extension
        #: If there is a write extension
        self.write_extension = write_extension
        #: If there is a write extension
        self.read_extension = read_extension


class BusEntryConfig(object):
    """A bus entry belonging to a field"""
    def __init__(self, name, bus, index):
        # type: (str, str, int) -> None
        #: The name of the register, like INPA_DLY
        self.name = name.replace('.', '_')
        #: The bus the output is on, like bit
        self.bus = bus
        #: The bus index, like 5
        self.index = index


class FieldConfig(object):
    """The config for a single Field of a Block"""
    #: Regex for matching a type string to this field
    type_regex = None

    def __init__(self, name, number, type, description, extra_config):
        # type: (str, int, str, str, Dict[str, str]) -> None
        # Field names should be UPPER_CASE_OR_NUMBERS
        assert re.match(r"[A-Z][0-9A-Z_\.]*$", name), \
            "Expected FIELD_NAME, got %r" % name
        #: The name of the field relative to it's Block, like INPA
        self.name = name
        #: The number of instances Blocks that will be created, like 8
        self.number = number
        #: The complete type string, like param lut
        self.type = type  # type: str
        #: The long description of the field
        self.description = description
        #: The list of registers this field uses
        self.registers = []  # type: List[RegisterConfig]
        #: The list of bus entries this field has
        self.bus_entries = []  # type: List[BusEntryConfig]
        #: If a write strobe is required, set wstb to 1
        self.wstb = extra_config.pop("wstb", False)
        #: If the field is associated to an option
        self.option_filter = extra_config.pop("if-option", "")
        #: Store the initial value, if supplied - only for params
        self.initial_value = extra_config.pop("initial_value", None)
        if self.initial_value:
            assert "param" in self.type, \
                "Only Param fields can have initial values"
        #: Store the extension register info
        self.extension = extra_config.pop("extension", None)
        self.extension_write = extra_config.pop("extension_write", "")
        self.extension_read = extra_config.pop("extension_read", "")
        self.extension_nums = []
        self.no_config = False
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

            # The following is used if fields use the extension server
            if r.extension:
                # Add register number for any read extensions
                for num, ext_type in self.extension_nums:
                    if ext_type == "read":
                        result.extend(str(' '.join(str(num) )))
                # If there are write extensions add W and then any register numbers
                if r.write_extension:
                    result.extend(['W'])
                    for num, ext_type in self.extension_nums:
                        if ext_type == "write":
                            result.extend(str(' '.join(str(num) )))
                result.extend(['X', r.extension])
            elif r.number >= 0:
                result.append(str(r.number))
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
        # Reverse these so we get EnumParamFieldConfig (specific) before
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
                d = OrderedDict(ini.items(section))
                typ = d.pop("type")
                desc = d.pop("description")
                subclass = FieldConfig.lookup_subclass(typ)
                assert subclass, "No FieldConfig for %r" % typ
                try:
                    ret.append(subclass(section, number, typ, desc, d))
                except TypeError as e:
                    raise TypeError("Cannot create %s from %s: %s" % (
                        subclass.__name__, d, e))
        return ret


class BitOutFieldConfig(FieldConfig):
    """These fields represent a single entry on the bit bus"""
    type_regex = "bit_out"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig(self.name, "bit", counters.new_bit()))


class PosOutFieldConfig(FieldConfig):
    """These fields represent a position output"""
    type_regex = "pos_out"
    scale = None
    offset = None
    units = None

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig(self.name, "pos", counters.new_pos()))

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> iter[str]
        self.scale = extra_config.pop("scale", 1)
        self.offset = extra_config.pop("offset", 0)
        self.units = extra_config.pop("units", "")
        return iter(())

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        if self.units:
            return "pos_out %s %s %s" % (self.scale, self.offset, self.units)
        else:
            # In case no units are declared, this removes trailing whitespace
            return "pos_out %s %s" % (self.scale, self.offset)


class ExtOutFieldConfig(FieldConfig):
    """These fields represent a ext output"""
    type_regex = "ext_out"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.append(
                BusEntryConfig(self.name, "ext", counters.new_ext()))


class ExtOutTimeFieldConfig(ExtOutFieldConfig):
    """These fields represent a ext output timestamp, which requires two
    registers"""
    type_regex = "ext_out timestamp"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        for _ in range(self.number):
            self.bus_entries.extend([
                BusEntryConfig(self.name + "_L", "ext", counters.new_ext()),
                BusEntryConfig(self.name + "_H", "ext", counters.new_ext())])


class TableFieldConfig(FieldConfig):
    """These fields represent a table field"""
    type_regex = "table"
    #: How many 32-bit words per line?
    words = None

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        # Hardcode to 2^8 = 256 pages
        # Each page is 1024 words = 4096 bytes
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
        for hibit, v in extra_config.items():
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

    #: How many lines in the table?
    lines = None

    def parse_extra_config(self, extra_config):
        self.lines = extra_config.pop("lines")
        for x in super(TableShortFieldConfig, self).parse_extra_config(
                extra_config):
            yield x

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        length = int(self.words) * int(self.lines)
        self.registers.extend([
            RegisterConfig(self.name, prefix='short %s' % length),
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
            address = -1
        else:
            address = counters.new_field()

        self.registers.append(
            RegisterConfig(self.name, address, extension=self.extension, write_extension=self.extension_write, read_extension=self.extension_read))

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        if self.initial_value:
            return "%s = %s" % (self.type, self.initial_value)
        else:
            return super(ParamFieldConfig, self).config_line()

class CalcExtensionFieldConfig(ParamFieldConfig):
    """These fields act in the same way as write record from the VHDL generation 
    point of view, but do not have a config entry"""
    type_regex = "(extension_write|extension_read)"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        super(CalcExtensionFieldConfig, self).register_addresses(counters)
        self.no_config = True

class EnumParamFieldConfig(ParamFieldConfig):
    """An enum field with its integer entries and string values"""
    type_regex = "(param|read|write) enum"

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> Iterable[str]
        for k, v in extra_config.items():
            assert k.isdigit(), "Only expecting integer enum entries in %s" % (
                extra_config,)
            yield "%s %s" % (pad(k, spaces=3), v)


class UintParamFieldConfig(ParamFieldConfig):
    """A special These fields represent all other set/get parameters backed with
     a single register"""
    type_regex = "(param|read|write) uint"

    max_value = None

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> iter[str]
        self.max_value = extra_config.pop("max_value", None)
        return super(UintParamFieldConfig, self).parse_extra_config(
            extra_config)

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        if self.max_value:
            return "%s %s" % (self.type, self.max_value)
        else:
            return super(UintParamFieldConfig, self).config_line()


class ScalarParamFieldConfig(ParamFieldConfig):
    """ A special Read config for reading the different config of a
    read scalar"""
    type_regex = "(param|read|write) scalar"

    scale = None
    offset = None
    units = None

    def parse_extra_config(self, extra_config):
        # type: (Dict[str, Any]) -> iter[str]
        self.scale = extra_config.pop("scale", 1)
        self.offset = extra_config.pop("offset", 0)
        self.units = extra_config.pop("units", "")
        return super(ScalarParamFieldConfig, self).parse_extra_config(
            extra_config)

    def config_line(self):
        # type: () -> str
        """Produce the line that should go in the config file after name"""
        if self.units:
            return "%s %s %s %s" % (
                self.type, self.scale, self.offset, self.units)
        else:
            # In case no units are declared, this removes trailing whitespace
            return "%s %s %s" % (self.type, self.scale, self.offset)


class BitMuxFieldConfig(FieldConfig):
    """These fields represent a single entry on the pos bus"""
    type_regex = "bit_mux"

    def register_addresses(self, counters):
        # type: (FieldCounter) -> None
        # One register for the mux value, one for a delay line
        self.registers.extend([
            RegisterConfig(self.name, counters.new_field()),
            RegisterConfig(self.name + "_DLY", counters.new_field())])


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


class TargetSiteConfig(object):
    """The config for the target sites"""
    #: Regex for matching a type string to this field
    type_regex = None

    def __init__(self, name, num, type=None):
        # type: (str, int, str)-> None
        #: The type of target site (SFP/FMC etc)
        self.name = name
        #: The info i in a string such as "3, i, io, o"
        self.number = int(num)
        self.type = type if type else name
        self.locations = [str(i) for i in range(1, self.number + 1)]
