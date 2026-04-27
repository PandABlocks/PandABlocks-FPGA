#!/usr/bin/env python3
from .dio_support import gpio_helper


class Extension:
    def __init__(self, count):
        assert count <= 2, 'Max 2 di inputs supported'
        self.count = count

    def parse_write(self, spec):
        def set_term(num, value):
            gpio_helper.set_output(num + 8, 1 if value else 0)

        return set_term
