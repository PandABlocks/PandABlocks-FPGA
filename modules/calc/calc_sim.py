from common.python.simulations import BlockSimulation, properties_from_ini


NAMES, PROPERTIES = properties_from_ini(__file__, "calc.block.ini")


class CalcSimulation(BlockSimulation):
    INPA, INPB, INPC, INPD, TYPEA, TYPEB, TYPEC, TYPED, FUNC, SHIFT, OUT \
        = PROPERTIES

    def on_changes(self, ts, changes):
        """Handle changes at a particular timestamp, then return the timestamp
        when we next need to be called"""
        super(CalcSimulation, self).on_changes(ts, changes)

        inpa = self.INPA * (-1 if self.TYPEA else 1)
        inpb = self.INPB * (-1 if self.TYPEB else 1)
        inpc = self.INPC * (-1 if self.TYPEC else 1)
        inpd = self.INPD * (-1 if self.TYPED else 1)

        assert self.FUNC == 0, "Only A+B+C+D functions currently supported"
        self.OUT = (inpa + inpb + inpc + inpd) >> self.SHIFT
