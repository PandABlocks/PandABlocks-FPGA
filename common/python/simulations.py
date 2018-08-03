import os
from collections import namedtuple

import numpy as np

from .ini_util import read_ini
from .configs import FieldConfig
from .compat import TYPE_CHECKING, add_metaclass

if TYPE_CHECKING:
    from typing import List, Optional, Dict, Tuple, Any

# These are the powers of two in an array
POW_TWO = 2 ** np.arange(32, dtype=np.uint32)


def properties_from_ini(src_path, ini_name):
    # type: (str, str) -> Tuple[Any, List[property]]
    assert ini_name.endswith(".block.ini"), \
        "Expected <block>.block.ini, got %s" % ini_name
    block_name = ini_name[:-len(".block.ini")]
    ini_path = os.path.join(os.path.dirname(src_path), ini_name)
    ini = read_ini(ini_path)
    properties = []
    names = []
    for field in FieldConfig.from_ini(ini, number=1):
        names.append(field.name)
        prop = property(field.getter, field.setter)
        properties.append(prop)
    # Create an object BlockNames with attributes FIELD1="FIELD1", F2="F2", ...
    names = namedtuple("%sNames" % block_name.title(), names)(*names)
    return names, properties


class BlockSimulationMeta(type):
    """Metaclass to make sure all field names are bound to the correct
    instance attribute names"""
    def __new__(cls, clsname, bases, dct):
        for name, val in dct.items():
            if isinstance(val, property) and \
                    isinstance(val.fget.im_self, FieldConfig):
                assert name == val.fget.im_self.name, \
                    "Property %s mismatch with FieldConfig name %s" % (
                        name, val.fget.im_self.name)
        return super(BlockSimulationMeta, cls).__new__(cls, clsname, bases, dct)


@add_metaclass(BlockSimulationMeta)
class BlockSimulation(object):
    bit_bus = np.zeros(128, dtype=np.bool_)
    pos_bus = np.zeros(32, dtype=np.int32)

    #: This will be dictionary with changes pushed by any properties created
    #: with properties_from_ini()
    changes = None

    @classmethod
    def bits_to_int(cls, bits):
        """Convert 32 element bit array into an int number"""
        return np.dot(bits, POW_TWO)

    def on_changes(self, ts, changes):
        # type: (int, Dict[str, int]) -> Optional[int]
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # Set attributes
        for name, value in changes.items():
            assert hasattr(self, name), "%s has no attribute %s" % (self, name)
            setattr(self, name, value)
        return None

