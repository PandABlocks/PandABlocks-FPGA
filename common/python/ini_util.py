import os
from collections import OrderedDict

from .compat import configparser, TYPE_CHECKING, str_

if TYPE_CHECKING:
    from typing import Iterable, Tuple, Dict, List, Union


def read_ini(paths):
    # type: (Union[List[str], str]) -> configparser.SafeConfigParser
    app_ini = configparser.ConfigParser()
    read_ok = app_ini.read(paths)
    if isinstance(paths, str_):
        paths = [paths]
    errored = set(paths) - set(read_ok)
    assert not errored, "Can't read ini files %s" % [
        os.path.abspath(x) for x in sorted(errored)]
    return app_ini


def ini_get(ini, section, field, default):
    try:
        return ini.get(section, field)
    except configparser.NoOptionError:
        return default


def parse_assigments(line):
    # type: (str) -> Dict[str, str]
    """Parse name1=value1, name2=value2 into an OrderedDict"""
    ret = OrderedDict()
    line = line.strip()
    if line:
        for assignment in line.split(","):
            split = assignment.split("=")
            assert len(split) == 2, \
                "Expected name=value, got %r" % line
            ret[split[0].strip()] = split[1].strip()
    return ret


def timing_entries(ini,  # type: configparser.SafeConfigParser
                   section  # type: str
                   ):
    # type: (...) -> Iterable[Tuple[int, Dict[str, str], Dict[str, str]]]
    """Parse timing lines from ini file, returning timing entries

    Args:
        ini: The ini files to parse
        section: The name of the section to generate lines from

    Returns:
        A list of timing entries. Each entry is a tuple of (ts, inputs, outputs)
        where inputs and outputs are dictionaries mapping the string field name
        to its string value
    """
    for ts, line in ini.items(section):
        ts = int(ts)
        split = line.split("->")
        assert len(split) in (1, 2), \
            "Expected ts1: k1=v1, k2=v2 -> k3=v3, k4=v4, got '%s: %s'" %(
                ts, line)
        inputs = parse_assigments(split[0])
        if len(split) == 2:
            outputs = parse_assigments(split[1])
        else:
            outputs = {}
        yield ts, inputs, outputs
