#!/usr/bin/env python3
from .dio_support import gpio_helper


class Extension:
    def __init__(self, count):
        assert count <= 4, 'Max 4 st_dio outputs supported'
        self.count = count

    def parse_write(self, spec):
        match spec:
            case 'dir':
                def set_output(num, value):
                    gpio_helper.set_output(num + 10, 1 if value else 0)
                    return (value,)

                return set_output
            case 'term':
                def set_term(num, value):
                    gpio_helper.set_output(num + 4, 1 if value else 0)

                return set_term
            case _:
                raise ValueError(f"Unknown st_dio spec: {spec}")
