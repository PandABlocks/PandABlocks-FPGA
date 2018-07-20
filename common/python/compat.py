try:
    # Python2
    from ConfigParser import SafeConfigParser
except ImportError:
    # Python3
    from configparser import SafeConfigParser

try:
    # For type checking only
    from typing import TYPE_CHECKING
except ImportError:
    TYPE_CHECKING = False
