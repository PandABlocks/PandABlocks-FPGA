#!/usr/bin/env python3
from .dio_support import gpio_helper


class Extension:
    def __init__(self, count):
        assert count <= 4, 'Max 4 dio outputs supported'
        self.count = count

    def parse_write(self, spec):
        assert spec.strip() == 'dir', 'Only "dir" write spec supported'
        def set_output(num, value):
            gpio_helper.set_output(num, 1 if value else 0)
            return (value,)

        return set_output
