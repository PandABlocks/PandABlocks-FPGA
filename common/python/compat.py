try:
    # Python2
    import ConfigParser as configparser
except ImportError:
    # Python3
    import configparser

try:
    # For type checking only
    from typing import TYPE_CHECKING
except ImportError:
    TYPE_CHECKING = False
