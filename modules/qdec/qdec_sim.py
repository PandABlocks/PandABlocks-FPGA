from collections import deque

from common.python.simulations import BlockSimulation, properties_from_ini


NAMES, PROPERTIES = properties_from_ini(__file__, "qdec.block.ini")

# Map (A, B) to quadrature state
STATE = {
    (0, 0): 0,
    (1, 0): 1,
    (1, 1): 2,
    (0, 1): 3
}


class QdecSimulation(BlockSimulation):
    LINKUP_INCR, A, B, Z, RST_ON_Z, SETP, HOMED, OUT = PROPERTIES

    def __init__(self):
        self.state = 0
        # Queue of delta values, 2 long when a change is queued to match
        # qdecoder delay
        self.queue = deque()

    def on_changes(self, ts, changes):
        super(QdecSimulation, self).on_changes(ts, changes)

        if self.queue:
            self.OUT += self.queue.popleft()

        if changes.get(NAMES.SETP, None):
            # HOMED on SETP
            self.OUT = self.SETP
            self.HOMED = 1
        elif self.LINKUP_INCR == 0:
            # If coder loss reset HOMED
            self.HOMED = 0
        elif self.RST_ON_Z == 1 and self.Z == 1:
            # HOMED on Reset when Z is '1' provided that RST_ON_Z is also '1'    
            self.OUT = 0
            self.HOMED = 1

        # New quadrature state (0..3)
        new_state = STATE[(self.A, self.B)]
        # Difference between last state and new state
        transition = (new_state - self.state) % 4
        self.state = new_state
        delta = 0
        if transition == 1:
            # Step forwards
            delta = 1
        elif transition == 3:
            # Step backwards
            delta = -1
        if delta and not self.queue:
            # add it to the queue
            self.queue.append(0)
            self.queue.append(delta)

        if self.queue:
            return ts + 1
