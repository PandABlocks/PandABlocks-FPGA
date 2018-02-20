from common.python.pandablocks.block import Block
import os
import csv

# for directions
FWD = 0
BWD = 1


class Pcomp(Block):

    def __init__(self):
        # Next compare point
        self.cpoint = 0
        # Next compare output
        self.cout = 1
        # Produced pulses
        self.cnum = 0
        # State to capture waiting before the position crosses the start point
        self.wait_start = True
        # flag an error on next ts?
        self.flag_error = False

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        if self.flag_error:
            self.ERROR = 1
            self.ACTIVE = 0
            self.OUT = 0
            self.flag_error = False

        # handle enable transitions
        if b.ENABLE in changes:
            if self.ENABLE:
                self.ACTIVE = 1
                # if relative then start position is from current pos
                if self.RELATIVE:
                    self.cpoint = self.START + self.INP
                else:
                    self.cpoint = self.START
                self.wait_start = True
                self.cnum = 0
                self.ERROR = 0
            else:
                self.ACTIVE = 0
                self.OUT = 0

        # check to see if we are waiting to cross the start point
        if self.ACTIVE:
            if self.DIR == FWD and self.INP < self.cpoint - self.DELTAP or \
                    self.DIR == BWD and self.INP > self.cpoint + self.DELTAP:
                self.wait_start = False

            # Handle pulses
            if self.DIR == FWD:
                transition = self.INP >= self.cpoint
            else:
                transition = self.INP <= self.cpoint
            if transition and not self.wait_start:
                if self.OUT == 0:
                    if self.DIR == FWD:
                        self.cpoint += self.WIDTH
                        if self.INP > self.cpoint:
                            self.flag_error = True
                            return ts + 1                            
                    else:
                        self.cpoint -= self.WIDTH                    
                        if self.INP < self.cpoint:
                            self.flag_error = True
                            return ts + 1                                                    
                    self.OUT = 1
                    self.cnum += 1
                else:
                    if self.DIR == FWD:
                        self.cpoint += self.STEP - self.WIDTH
                        if self.INP > self.cpoint:
                            self.flag_error = True
                            return ts + 1                           
                    else:
                        self.cpoint -= self.STEP - self.WIDTH
                        if self.INP < self.cpoint:
                            self.flag_error = True
                            return ts + 1                           
                    self.OUT = 0
                    # if we've done PNUM, then stop
                    if self.cnum >= self.PNUM:
                        self.ACTIVE = 0

