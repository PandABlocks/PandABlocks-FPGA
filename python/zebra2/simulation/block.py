import numpy as np

from ..configparser import ConfigParser


# These are the powers of two in an array
POW_TWO = 2 ** np.arange(32, dtype=np.uint32)


class Block(object):
    bit_bus = np.zeros(128, dtype=np.bool_)
    pos_bus = np.zeros(32, dtype=np.int32)
    enc_bus = np.zeros(4, dtype=np.int32)

    @classmethod
    def bits_to_int(cls, bits):
        """Convert 32 element bit array into an int number"""
        return np.dot(bits, POW_TWO)

    @classmethod
    def load_config(cls, config_dir):
        """Load the config def, then add properties to subclasses"""
        cls.parser = ConfigParser(config_dir)
        cls.bit_bus.fill(0)
        cls.pos_bus.fill(0)
        cls.enc_bus.fill(0)
        i = cls.parser.bit_bus["BITS.ONE"]
        cls.bit_bus[i] = 1
        for subclass in cls.__subclasses__():
            subclass.add_properties()

    @classmethod
    def add_properties(cls):
        cls.block_name = cls.__name__.upper()
        cls.config_block = cls.parser.blocks[cls.block_name]
        # compute list of attribute names
        attr_names = cls.config_block.registers.keys() + \
            cls.config_block.outputs.keys()
        # augment with PCAP special fields
        if cls.block_name == "PCAP":
            for name in cls.parser.blocks["*REG"].registers:
                if name.startswith("PCAP_"):
                    attr_name = name[len("PCAP_"):]
                    attr_names.append(attr_name)
                    setattr(cls.config_block, attr_name, attr_name)
            # Special DATA output should appear in changes each time
            # it is written to
            cls.add_property("DATA", True)
            # Special ERROR output
            cls.add_property("ERROR")
        # add a property that stores changes for outputs
        for name in attr_names:
            cls.add_property(name)

    @classmethod
    def add_property(cls, attr, force=False):

        def setter(self, v):
            if force or getattr(self, attr) != v:
                if not hasattr(self, "_changes"):
                    self._changes = {}
                setattr(self, "_%s" % attr, v)
                self._changes[attr] = v

        def getter(self):
            return getattr(self, "_%s" % attr, 0)

        setattr(cls, attr, property(getter, setter))

    def on_changes(self, ts, changes):
        for name, value in changes.items():
            setattr(self, name, value)
        return None
