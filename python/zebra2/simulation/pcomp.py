from .block import Block


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


    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

         #check to see if we are waiting to cross the start point
        if self.ENABLE and b.INP in changes:
            if self.DIR == FWD and self.INP < self.cpoint - self.DELTAP:
                self.wait_start = False
            elif self.DIR == BWD and self.INP > self.cpoint + self.DELTAP:
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
        if self.ENABLE:
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
        if self.tnext:
            return self.tnext
