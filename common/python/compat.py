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

try:
    # Python2
    str_ = basestring
except NameError:
    # Python3
    str_ = str

# Taken from six
def add_metaclass(metaclass):
    """Class decorator for creating a class with a metaclass."""
    def wrapper(cls):
        orig_vars = cls.__dict__.copy()
        orig_vars.pop('__dict__', None)
        orig_vars.pop('__weakref__', None)
        return metaclass(cls.__name__, cls.__bases__, orig_vars)
    return wrapper
