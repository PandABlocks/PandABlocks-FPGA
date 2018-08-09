# Classes for representing an INI file where keys and sections are unique

import sys
import ConfigParser


class IniFile:
    def __init__(self, **kargs):
        self.__sections = kargs

    def add_section(self, section):
        assert section.name not in self.__sections
        self.__sections[section.name] = section

    def add_sections(self, sections):
        for section in sections:
            self.add_section(section)

    def __getitem__(self, name):
        return self.__sections[name]

    def __iter__(self):
        return self.__sections.itervalues()

    def emit(self, outfile = sys.stdout):
        for section in self:
            section.emit(outfile)
            print >>outfile


class Section:
    def __init__(self, name, **kargs):
        self.name = name
        self.__keys = kargs

    def add_key(self, key, value):
        assert key not in self.__keys
        self.__keys[key] = value

    def __setitem__(self, key, value):
        self.add_key(key, value)

    def __getitem__(self, key):
        return self.__keys[key]

    def __iter__(self):
        return self.__keys.iteritems()

    def emit(self, outfile = sys.stdout):
        print >>outfile, '[%s]' % self.name
        for key, value in self:
            print >>outfile, '%s: %s' % (key, value)


def load_ini_file(filename):
    parser = ConfigParser.RawConfigParser()
    parser.readfp(open(filename))
    ini = IniFile()
    for section_name in parser.sections():
        ini.add_section(
            Section(section_name, **dict(parser.items(section_name))))
    return ini


class CompareFail(Exception):
    pass

# Checks that all sections and fields in other are present in base.  Raises a
# CompareFail() exception if a mismatch is found.
def compare_ini(match, other):
    for section in match:
        try:
            other_section = other[section.name]
        except KeyError:
            raise CompareFail('Section "%s" not present' % section.name)
        else:
            for key, value in section:
                try:
                    other_value = other_section[key]
                except KeyError:
                    raise CompareFail(
                        'Option "%s.%s" not present' % (section.name, key))
                else:
                    if value != other_value:
                        raise CompareFail(
                            'Option "%s.%s": value "%s" != "%s"' % (
                                section.name, key, value, other_value))


if __name__ == '__main__':
    ini = load_ini_file(sys.argv[1])
    if len(sys.argv) == 2:
        ini.emit()
    else:
        match = load_ini_file(sys.argv[2])
        compare_ini(match, ini)
        print 'Match ok'
