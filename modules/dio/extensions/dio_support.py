from pandai2c import smbus2


class GPIO_Helper:
    ADDR = 0x21
    DIR_BASE = 0x18
    OUT_BASE = 0x8

    def __init__(self):
        self.bus = smbus2.SMBus(0)
        self.set_channel()
        for bank in range(2):
            self.write_reg(self.DIR_BASE + bank, 0x0)

    def set_channel(self):
        # TODO: make this an atomic operation together with the read/write to
        # the GPIO expander. I tried using repeated start conditions but it
        # doesn't seem to work with the current hardware setup. For now, we just
        # assume that nothing else is trying to access the I2C bus at the same
        # time.
        self.bus.write_byte(0x70, 0x20)

    def write_reg(self, reg, value):
        self.set_channel()
        self.bus.write_byte_data(self.ADDR, reg, value)

    def read_reg(self, reg):
        self.set_channel()
        val = self.bus.read_byte_data(self.ADDR, reg)
        return val

    def set_direction(self, pin, direction):
        bank = pin // 8
        pin = pin % 8
        current_val = self.read_reg(self.DIR_BASE + bank)
        self.write_reg(self.DIR_BASE + bank,
            current_val | (1 << pin) if direction else current_val & ~(1 << pin))

    def set_output(self, pin, value):
        bank = pin // 8
        pin = pin % 8
        current_val = self.read_reg(self.OUT_BASE + bank)
        self.write_reg(self.OUT_BASE + bank,
            current_val | (1 << pin) if value else current_val & ~(1 << pin))


# We need a single GPIO controller shared between all instances
gpio_helper = GPIO_Helper()
