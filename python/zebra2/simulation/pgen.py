from .block import Block
import os
import csv

class Pgen(Block):
    def __init__(self):
        self.table_data = []
        self.current_line = 0
        self.current_cycle = 0
        self.active = 0

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        if b.TABLE_ADDRESS in changes:
            self.active = 1
            #open the table
            file_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..",
                                    "tests", "sim_sequences", "long_tables",
                                    self.TABLE_ADDRESS)

            assert os.path.isfile(file_dir), "%s does not exist" % (file_dir)
            with open(file_dir, "rb") as table:
                reader = csv.DictReader(table)
                self.table_data = [int(line['POS']) for line in reader]

        if b.TRIG in changes and self.TRIG:
            #send an output from the table on rising TRIG edge if enabled
            if self.ENABLE and self.active:
                self.OUT = self.table_data[self.current_line]
                self.current_line += 1
                if self.current_line == len(self.table_data):
                    self.current_cycle += 1
                    self.current_line = 0
                if self.current_cycle == self.CYCLES: self.active = 0