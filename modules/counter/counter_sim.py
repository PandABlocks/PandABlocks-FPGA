from common.python.simulations import BlockSimulation, properties_from_ini, \
    TYPE_CHECKING
import numpy
if TYPE_CHECKING:
    from typing import Dict


UP = 0
DOWN = 1

# OUT_MODE enum values
MODE_OnChange = 0
MODE_OnDisable = 1

NAMES, PROPERTIES = properties_from_ini(__file__, "counter.block.ini")


class CounterSimulation(BlockSimulation):
    ENABLE, TRIG, DIR, TRIG_EDGE, OUT_MODE, START, STEP, MAX, MIN, CARRY, OUT = PROPERTIES
    
    def __init__(self):
        self.counter = 0
        self.overflow = 0

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(CounterSimulation, self).on_changes(ts, changes)
        # This is a ConfigBlock object for us to get our strings from

        if self.MAX == 0 and self.MIN == 0:
            MIN = numpy.iinfo(numpy.int32).min
            MAX = numpy.iinfo(numpy.int32).max
        else:
            MIN = self.MIN
            MAX = self.MAX
        
        # Set attributes
        for name, value in changes.items():
            setattr(self, name, value)

        # Calculation of trigger signal
        if NAMES.TRIG in changes:
            got_trigger = (self.TRIG_EDGE == 0 and self.TRIG) or \
                          (self.TRIG_EDGE == 1 and not self.TRIG) or \
                           self.TRIG_EDGE == 2
        else:
            got_trigger = False

        if self.OUT_MODE == MODE_OnChange:
            if changes.get(NAMES.ENABLE, None) is 1:
                self.OUT = self.START
            elif changes.get(NAMES.ENABLE, None) is 0:
                self.CARRY = 0
            elif self.ENABLE and NAMES.TRIG in changes:
                # stop the counter_carry on next trigger edge
                if self.CARRY:
                    self.CARRY = 0
                # process trigger on selected edge
                if got_trigger:
                    if self.STEP == 0:
                        step = 1
                    else:
                        step = self.STEP
                    if self.DIR == DOWN:
                        step = -step
                    self.OUT += step
                    if self.OUT > MAX:
                        self.OUT -= MAX - MIN + 1
                        self.CARRY = 1
                    elif self.OUT < MIN:
                        self.OUT += MAX - MIN + 1
                        self.CARRY = 1
        elif self.OUT_MODE == MODE_OnDisable:
            if changes.get(NAMES.ENABLE, None) is 1:
                self.counter = self.START
                self.overflow = 0
            elif self.ENABLE and NAMES.TRIG in changes:
                # process trigger on selected edge
                if got_trigger:
                    if self.STEP == 0:
                        step = 1
                    else:
                        step = self.STEP
                    if self.DIR == DOWN:
                        step = -step
                    self.counter += step
                    if self.counter > MAX:
                        self.counter -= MAX - MIN + 1
                        self.overflow = 1
                    elif self.counter < MIN:
                        self.counter += MAX - MIN + 1
                        self.overflow = 1
            elif changes.get(NAMES.ENABLE, None) is 0:
                self.OUT = self.counter
                self.CARRY = self.overflow