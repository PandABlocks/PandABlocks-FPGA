# Classes for representing an INI file where keys and sections are unique

from __future__ import print_function

import sys
from configparser import ConfigParser
import collections


class IniFile:
    def __init__(self):
        self.__sections = collections.OrderedDict()

    def add_section(self, section):
        assert section.name not in self.__sections
        self.__sections[section.name] = section

    def add_sections(self, sections):
        for section in sections:
            self.add_section(section)

    def __getitem__(self, name):
        return self.__sections[name]

    def get(self, name, default):
        try:
            return self[name]
        except KeyError:
            return default

    def __iter__(self):
        return self.__sections.itervalues()

    def emit(self, outfile = sys.stdout):
        for section in self:
            section.emit(outfile)
            print(file = outfile)


class Section:
    def __init__(self, name):
        self.name = name
        self.__keys = collections.OrderedDict()

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
        print('[%s]' % self.name, file = outfile)
        for key, value in self:
            print('%s: %s' % (key, value), file = outfile)


def load_ini_file(filename):
    parser = ConfigParser()
    parser.readfp(open(filename))
    ini = IniFile()
    for section_name in parser.sections():
        section = Section(section_name)
        ini.add_section(section)
        for key, value in parser.items(section_name):
            section[key] = value
    return ini


class CompareFail(Exception):
    pass

# Checks that all sections and fields in other are present in base.  Raises a
# CompareFail() exception if a mismatch is found.
def compare_ini(match, other, ignore = []):
    # First filter out sections we're told to ignore
    match = filter(lambda s: s.name not in ignore, match)
    for section in match:
        try:
            other_section = other[section.name]
        except KeyError:
            raise CompareFail('Section "%s" not present' % section.name)
        else:
            for key, value in section:
                try:
                    other_value = str(other_section[key])
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
        print('Match ok')
