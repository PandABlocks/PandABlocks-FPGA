from .block import Block


# for directions
FWD = 0
BWD = 1


class Pcomp(Block):

    def __init__(self):
        # Current direction of POSN stream
        self.tdir = FWD
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

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        # This is a ConfigBlock object for use to get our strings from
        b = self.config_block

        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # If changing the DELTAT filter then init values
        if b.FLTR_DELTAT in changes:
            if self.FLTR_DELTAT:
                self.tnext = ts + self.FLTR_DELTAT
                self.tposn = self.POSN
            else:
                self.tnext = 0

        # calculate current dir of POSN on deltat
        if self.tnext and ts > self.tnext:
            deltap = self.POSN - self.tposn
            if deltap > self.FLTR_THOLD:
                self.tdir = FWD
            elif deltap < self.FLTR_THOLD:
                self.tdir = BWD
            self.tnext = ts + self.FLTR_DELTAT
            self.tposn = self.POSN

        # handle enable transitions
        if b.ENABLE in changes:
            if self.ENABLE:
                # if relative then start position is from current pos
                if self.RELATIVE:
                    self.cpoint = self.START + self.POSN
                else:
                    self.cpoint = self.START
                # next pulse should be 1
                self.cout = 1
                # reset num points counter
                self.cnum = 0
            else:
                self.ACT = 0
                self.PULSE = 0

        # handle pulses if active
        if self.ENABLE:
            # check if transition
            if self.DIR == FWD:
                transition = self.POSN >= self.cpoint
            else:
                transition = self.POSN <= self.cpoint
            # if direction filter is on, then check it matches
            if self.tnext:
                transition &= self.DIR == self.tdir
            # if transition then set output and increment compare point
            if transition:
                self.ACT = 1
                self.PULSE = self.cout
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
                    # if we've done NUM, then stop
                    if self.cnum >= self.NUM:
                        self.ACT = 0
                    else:
                        self.cout = 1

        if self.tnext:
            return self.tnext
