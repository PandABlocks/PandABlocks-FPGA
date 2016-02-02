import numpy as np

from ..configparser import ConfigParser


class Block(object):
    bit_bus = np.zeros(128, dtype=np.bool_)
    bit_changes = np.zeros(128, dtype=np.bool_)
    pos_bus = np.zeros(32, dtype=np.int32)
    pos_changes = np.zeros(32, dtype=np.bool_)
    enc_bus = np.zeros(4, dtype=np.int32)

    @classmethod
    def load_config(cls, config_dir):
        """Load the config def, then add properties to subclasses"""
        cls.parser = ConfigParser(config_dir)
        for subclass in cls.__subclasses__():
            subclass.add_properties()

    @classmethod
    def add_properties(cls):
        cls.block_name = cls.__name__.upper()
        cls.config_block = cls.parser.blocks[cls.block_name]
        # compute list of attribute names
        attr_names = cls.config_block.registers.keys()
        # add any out registers
        for field_name, field in cls.config_block.fields.items():
            if field.cls and field.cls.endswith("_out"):
                attr_names.append(field_name)
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

    def on_event(self, ts, changes):
        for name, value in changes.items():
            setattr(self, name, value)
        return None
