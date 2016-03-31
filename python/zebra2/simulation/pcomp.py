from .block import Block
import os
import csv

# for directions
FWD = 0
BWD = 1


class Pcomp(Block):

    def __init__(self):
        # Next tick to check deltat
        self.tnext = 0
        # Last position cache for deltat check
        self.tposn = 0
        # Next compare point
        self.cpoint = 0
        # Next compare output
        self.cout = 1
        # Produced pulses
        self.cnum = 0
        #state to capture waiting before the position crosses the start point
        self.wait_start = True
        #table data from file
        self.table_data = []
        #current line in the table
        self.current_line = 0
        self.rise = 0
        self.fall = 0
        self.table_repeat = 0
        self.table_step = 0

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        #create a table if we have a long table input
        if b.TABLE_ADDRESS in changes:
            #open the table
            file_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..",
                                    "tests", "sim_sequences", "long_tables",
                                    self.TABLE_ADDRESS)
            assert os.path.isfile(file_dir), "%s does not exist" % (file_dir)
            with open(file_dir, "rb") as table:
                reader = csv.DictReader(table, delimiter='\t')
                self.table_data = [line for line in reader]

        #set the rise and fall points from the table
        if self.USE_TABLE and self.table_data:
            self.rise = int(self.table_data[self.current_line]['RISE'])
            self.fall = int(self.table_data[self.current_line]['FALL'])


            #determine the direction
            if self.fall - self.rise > 0:
                self.DIR = 0
                self.rise += self.table_step
                self.fall += self.table_step
            else:
                self.DIR = 1
                self.rise -= self.table_step
                self.fall -= self.table_step

            # handle enable transitions
            if b.ENABLE in changes:
                if self.ENABLE:
                    self.ACTIVE = 1
                    self.cpoint = self.START
                    # next pulse should be 1
                else:
                    self.ACTIVE = 0
                    self.OUT = 0
                    self.wait_start = True

             #check to see if we are waiting to cross the start point
            if self.ACTIVE:
                if self.DIR == FWD and self.INP < self.rise - self.DELTAP or\
                        self.DIR == BWD and self.INP > self.rise + self.DELTAP:
                    self.wait_start = False

            # handle pulses if active
                if self.DIR == FWD and not self.wait_start:
                    if self.INP >= self.rise:
                        self.OUT = 1
                    if self.INP >= self.fall:
                        self.OUT = 0
                        if self.current_line < self.TABLE_LENGTH/8:
                            self.current_line += 1
                elif self.DIR == BWD and not self.wait_start:
                    if self.INP <= self.rise:
                        self.OUT = 1
                    if self.INP <= self.fall:
                        self.OUT = 0
                        if self.current_line < self.TABLE_LENGTH/8:
                            self.current_line += 1

            #handle table repeats
                if self.table_repeat < self.PNUM \
                        and self.current_line == self.TABLE_LENGTH/8:
                    self.table_step += self.STEP
                    self.table_repeat += 1
                    self.current_line = 0
                elif self.table_repeat == self.PNUM:
                    self.ACTIVE = 0

        #behaviour without tables
        else:
             #check to see if we are waiting to cross the start point
            if self.ACTIVE:
                if self.DIR == FWD and self.INP < self.cpoint - self.DELTAP or\
                        self.DIR == BWD and self.INP > self.cpoint + self.DELTAP:
                    self.wait_start = False

            # handle enable transitions
            if b.ENABLE in changes:
                if self.ENABLE:
                    self.ACTIVE = 1
                    # if relative then start position is from current pos
                    if self.RELATIVE:
                        self.cpoint = self.START + self.INP
                    else:
                        self.cpoint = self.START
                    # next pulse should be 1
                    self.cout = 1
                    # reset num points counter
                    self.cnum = 0
                else:
                    self.ACTIVE = 0
                    self.OUT = 0
                    self.wait_start = True
            # handle pulses if active
            if self.ACTIVE:
                if self.DIR == FWD:
                    transition = self.INP >= self.cpoint and not self.wait_start
                else:
                    transition = self.INP <= self.cpoint and not self.wait_start
                if transition:
                    self.OUT = self.cout
                    if self.cout:
                        if self.DIR == FWD:
                            self.cpoint += self.WIDTH
                        else:
                            self.cpoint -= self.WIDTH
                        self.cout = 0
                        self.cnum += 1
                    else:
                        if self.DIR == FWD:
                            self.cpoint += self.STEP - self.WIDTH
                        else:
                            self.cpoint -= self.STEP - self.WIDTH
                        # if we've done PNUM, then stop
                        if self.cnum >= self.PNUM:
                            self.ACTIVE = 0
                        else:
                            self.cout = 1
                    if self.DIR == FWD and self.INP > self.cpoint\
                            or self.DIR == BWD and self.INP < self.cpoint:
                        self.ERROR = 1
                        self.ACTIVE = 0
                        self.OUT = 0
            if self.tnext:
                return self.tnext
