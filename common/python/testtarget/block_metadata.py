import logging
import re

from pathlib import Path
log = logging.getLogger(__name__)


class BlockMetadata(object):
    def __init__(self, config_dir: Path):
        self.config_dir = config_dir
        self.blocks = {}
        self.block_address_to_name = {}
        self.constants = {}
        self.load_config()

    def load_config(self):
        log.info(f'Loading config from {self.config_dir}')
        self.parse_registers()
        self.parse_config()
        self.parse_description()

    def get_instance_field_arg(self, field_path, expected_type=None):
        block_name, field_name = field_path.split('.', 1)
        if block_name[-1].isdigit():
            # in a field path, the instance number is always 1-based
            num = int(block_name[-1]) - 1
            block_name = block_name[:-1]
        else:
            num = 0
        if expected_type is not None:
            field_type = self.blocks[block_name]['fields'][field_name]['type']
            assert  field_type.startswith(expected_type), \
                f'Field {field_path} is not of expected type {expected_type}'
        return self.blocks[block_name]['fields'][field_name]['args'][num]

    def get_bit_index(self, field_path):
        return self.get_instance_field_arg(field_path, 'bit_out')

    def get_pos_index(self, field_path):
        return self.get_instance_field_arg(field_path, 'pos_out')

    # class(5 bits) & instance(4 bits) & register(6 bits) & "00"
    def reg_addr(self, cls, inst, reg):
        return (reg << 2) | (inst << 8) | (cls << 12)

    def get_block_name(self, block_addr):
        return self.block_address_to_name[block_addr]

    def reg_addr_from_field(self, field_path, arg_index=0):
        block_addr, inst, reg = self.get_indexes(field_path, arg_index)
        return self.reg_addr(block_addr, inst, reg)

    def get_indexes(self, field_path, arg_index=0):
        block_name, field_name = field_path.split('.', 1)
        if block_name[-1].isdigit():
            # in a field path, the instance number is always 1-based
            num = int(block_name[-1]) - 1
            block_name = block_name[:-1]
        else:
            num = 0
        reg = self.blocks[block_name]['fields'][field_name]['args'][arg_index]
        return (self.blocks[block_name]['address'], num, reg)

    def parse_registers(self):
        block_name = ""
        n_line = 1
        with open(self.config_dir / 'registers', 'r') as f:
            for line in f:
                sline = line.strip()
                if sline == '' or sline.startswith('#'):
                    continue

                log.debug(f'parse_registers: {n_line}: {line.strip()}')
                n_line += 1
                in_field = line.startswith(' ') or line.startswith('\t')
                if in_field:
                    assert block_name
                    field_name, args = sline.split(None, 1)
                    self.blocks[block_name]['fields'][field_name] = {
                        'args': [int(item) if item.isdigit() else item
                                 for item in args.split()]
                    }
                elif '=' in line:
                    key, value = sline.split('=', 1)
                    self.constants[key.strip()] = value.strip()
                else:
                    block_name, block_address = sline.split(None, 1)
                    if block_address.isdigit():
                        block_address = int(block_address)

                    self.blocks[block_name] = {
                        'address': block_address,
                        'fields': {}
                    }
                    self.block_address_to_name[block_address] = block_name

    def parse_config(self):
        block_name = None
        enum_values = None
        n_line = 1
        # This parsing is a simplification which doesn't properly handle the
        # table fields, but it's good enough for the required use-case.
        with open(self.config_dir / 'config', 'r') as f:
            for line in f:
                if line.strip() == '' or line.startswith('#'):
                    continue

                log.debug(f'parse_config: {n_line}: {line.strip()}')
                n_line += 1
                in_field = line.startswith(' ') or line.startswith('\t')
                if in_field:
                    assert block_name
                    enum_match = re.match(r'^\s*(\d+)\s+(.+)$', line.strip())
                    if enum_match:
                        assert enum_values is not None
                        enum_values[int(enum_match.group(1))] = \
                            enum_match.group(2)
                    else:
                        field_name, field_type = line.strip().split(None, 1)
                        field_name, field_type = \
                            field_name.strip(), field_type.strip()
                        field = self.blocks[block_name]['fields'].setdefault(
                            field_name, {})
                        field['type'] = field_type
                        if 'enum' in field_type:
                            enum_values = field.setdefault('enum', {})
                        else:
                            enum_values = None
                else:
                    match = re.match(r'^([^\[]+)\[(\d+)\]\s*$', line)
                    if match:
                        block_name = match.group(1)
                        n_instances = int(match.group(2))
                    else:
                        block_name = line.strip()
                        n_instances = 1

                    self.blocks.setdefault(block_name, {})['n'] = n_instances
                    self.blocks[block_name].setdefault('fields', {})

    def parse_description(self):
        block_name = None
        n_line = 1
        with open(self.config_dir / 'description', 'r') as f:
            for line in f:
                if line.strip() == '' or line.startswith('#'):
                    continue

                log.debug(f'parse_description: {n_line}: {line.strip()}')
                n_line += 1
                in_field = line.startswith(' ') or line.startswith('\t')
                if in_field:
                    assert block_name
                    field_name, description = line.strip().split(None, 1)
                    self.blocks[block_name]['fields'].setdefault(
                        field_name.strip(), {})['description'] = \
                        description.strip()
                else:
                    block_name, block_desc = line.strip().split(None, 1)
                    self.blocks.setdefault(
                        block_name, {}).setdefault('fields', {})
                    self.blocks[block_name]['description'] = block_desc
