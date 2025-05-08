from common.python.simulations import BlockSimulation, properties_from_ini
import os
import csv

from collections import deque

NAMES, PROPERTIES = properties_from_ini(__file__, "pgen.block.ini")
IDLE = 0
WAIT_ENABLE = 1
RUNNING = 2


class PgenSimulation(BlockSimulation):
    ENABLE, TRIG, TABLE, TABLE_ADDRESS, TABLE_LENGTH, REPEATS, ACTIVE, OUT, \
        STATE, HEALTH = PROPERTIES

    def __init__(self):
        self.table_data = []
        self.data = deque()
        self.data_repeats = 1
        self.current_line = 0
        self.current_cycle = 0
        self.state2function = {
            IDLE: self.idle_state,
            WAIT_ENABLE: self.wait_enable_state,
            RUNNING: self.running_state
        }
        self.go_idle = False

    def idle_state(self, ts, changes):
        self.ACTIVE = 0
        if self.table_data:
            self.STATE = WAIT_ENABLE

    def wait_enable_state(self, ts, changes):
        if not self.table_data:
            self.STATE = IDLE
        elif changes.get(NAMES.ENABLE, None) == 1:
            self.ACTIVE = 1
            self.STATE = RUNNING

    def running_state(self, ts, changes):
        if not self.table_data or changes.get(NAMES.ENABLE, None) == 0:
            self.ACTIVE = 0
            self.STATE = IDLE
        elif NAMES.TRIG in changes and self.TRIG:
            self.OUT = self.table_data[self.current_line]
            self.current_line += 1
            if self.current_line == self.TABLE_LENGTH:
                self.current_cycle += 1
                self.current_line = 0
            if self.current_cycle == self.REPEATS:
                self.go_idle = True

    def handle_table_write(self, ts, changes):
        if not self.data and \
                (self.data_repeats < self.REPEATS or self.REPEATS == 0):
            self.data_repeats += 1
            self.data.extend(self.data)
            self.data.append(None)

        if self.data:
            item = self.data.popleft()
            if item is not None:
                self.table_data.append(item)

        if NAMES.TABLE_LENGTH in changes:
            # open the table
            file_path = os.path.join(
                os.path.dirname(__file__), 'tests_assets',
                f'{self.TABLE_ADDRESS}.txt')
            assert os.path.isfile(file_path), "%s does not exist" % file_path
            with open(file_path, 'r') as f:
                lines = list(f)[1:]
            new_data = [int(line, 16) if line.startswith('0x') else
                        int(line) for line in lines]
            self.data.extend([None] * 5)
            self.data.extend(new_data)

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        super(PgenSimulation, self).on_changes(ts, changes)
        if self.go_idle:
            self.current_line = 0
            self.table_data = []
            self.data_repeats = 1
            self.data.clear()
            self.ACTIVE = 0
            self.STATE = IDLE
        else:
            self.state2function[self.STATE](ts, changes)

        self.handle_table_write(ts, changes)
        return ts + 1
