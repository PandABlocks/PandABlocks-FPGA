import os, csv

from matplotlib.sphinxext import plot_directive
from docutils.parsers.rst import Directive
from docutils import nodes, statemachine
from .ini_util import read_ini, timing_entries


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


class sequence_plot_node(nodes.Element):
    pass


class table_plot_node(nodes.Element):
    pass


class timing_plot_directive(Directive):

    has_content = False
    required_arguments = 0
    optional_arguments = 0
    option_spec = {'path': str, 'section': str, 'table': bool, 'nofigs': bool,
                   'xlabel': str}

    def catch_insert_input(self, total_lines, source=None):
        self.total_lines = total_lines

    def run(self):
        # fill the content code with the options from the directive
        path = self.options['path']
        section = self.options['section']

        # Parse the ini file and make any special tables
        path = os.path.join(ROOT, path)
        ini = read_ini(path)
        tables = []
        for ts, inputs, outputs in timing_entries(ini, section):
            for name, val in inputs.items():
                if name == "TABLE_ADDRESS":
                    tables = self.make_long_tables(ini, section, path)
                elif name == "TABLE_DATA":
                    tables = self.make_all_seq_tables(ini, section)
            for name, val in outputs.items():
                # TODO: PCAP_DATA
                if name == "DATA":
                    tables = self.make_pcap_table(ini, section)

        args = [path, section]
        if "xlabel" in self.options:
            args.append(self.options["xlabel"])
        plot_content = [
            "from common.python.timing_plot import make_timing_plot",
            "make_timing_plot(%s)" % (", ".join(repr(x) for x in args))]

        # override include_input so we get the result
        old_insert_input = self.state_machine.insert_input
        self.state_machine.insert_input = self.catch_insert_input

        d = plot_directive.PlotDirective(
            self.name, self.arguments, self.options, plot_content, self.lineno,
            self.content_offset, self.block_text, self.state,
            self.state_machine)
        d.run()

        self.state_machine.insert_input = old_insert_input
        plot_node = sequence_plot_node()
        node = sequence_plot_node()

        # do a nested parse of the lines
        self.state.nested_parse(
            statemachine.ViewList(initlist=self.total_lines),
            self.content_offset, plot_node)

        # add the directives
        node.append(plot_node)
        for table_node in tables:
            node.append(table_node)
        return [node]

    def make_pcap_table(self, sequence, sequence_dir):
        table_node = table_plot_node()
        # find the inputs that change
        input_changes = []
        data_header = []
        for ts, inputs, outputs in timing_entries(sequence, sequence_dir):
            for name in inputs:
                if "." in name:
                    input_changes.append(name)
                elif name == "START_WRITE":
                    data_header = []
                elif name == "WRITE":
                    if "x" in inputs[name]:
                        hdr_name = "0x%X" % int(inputs[name], 16)
                    else:
                        hdr_name = "0x%X" % int(inputs[name], 0)
                    data_header.append(hdr_name)
        if not data_header:
            return table_node
        table_hdr = ["Row"]
        # This contains instructions about how to process each data entry
        # - None: Just emit it
        # - str name: It is the higher order bits of a given name
        # - [int shift]: For each shifted value, emit the relevant bit entry
        bit_extracts = []
        for name in data_header:
            if name.startswith("BITS"):
                # Add relevant bit entries
                quadrant = int(name[4])
                shifts = []
                bit_extracts.append(shifts)
                for bus_name in input_changes:
                    r = range(quadrant * 32, (quadrant + 1) * 32)
                    idx = cparser.bit_bus.get(bus_name, None)
                    if idx in r and bus_name not in table_hdr:
                        table_hdr.append(bus_name)
                        shifts.append(idx - quadrant * 32)
            elif name.endswith("_H"):
                # This is the higher order entry
                bit_extracts.append(name[:-2])
            else:
                # Add pos entry
                bit_extracts.append(None)
                table_hdr.append(name)
        # Create a table
        table = nodes.table()
        table_node += table
        tgroup = nodes.tgroup(cols=len(table_hdr))
        table += tgroup
        for col_width in [len(x) for x in table_hdr]:
            tgroup += nodes.colspec(colwidth=col_width)
        # add the header
        thead = nodes.thead()
        tgroup += thead
        thead += self.make_row(table_hdr)
        # add the body
        tbody = nodes.tbody()
        tgroup += tbody
        # Add each row
        r = 0
        row = [r]
        high = {}
        i = 0
        for ts, inputs, outputs in timing_entries(sequence, sequence_dir):
            for names in outputs:
                if names == "DATA":
                    if "x" in outputs["DATA"]:
                        data = int(outputs["DATA"], 16)
                    else:
                        data = int(outputs["DATA"], 0)
                    if data is not None:
                        extract = bit_extracts[i]
                        if type(extract) == list:
                            for shift in extract:
                                row.append((data >> shift) & 1)
                        elif type(extract) == str:
                            high[extract] = data
                        else:
                            row.append(data)
                        i += 1
                        if i >= len(bit_extracts):
                            for name, val in high.items():
                                idx = [ix for ix, x in enumerate(table_hdr)
                                       if x == name][0]
                                row[idx] += val << 32
                            tbody += self.make_row(row)
                            r += 1
                            row = [r]
                            high = {}
                            i = 0
        return table_node

    def make_long_tables(self, sequence, sequence_dir, path):
        table_node = table_plot_node()
        alltables = []
        table_data = []
        table = nodes.table()
        path = os.path.dirname(os.path.abspath(path))
        for ts, inputs, outputs in timing_entries(sequence, sequence_dir):
            if 'TABLE_ADDRESS' in inputs:
                # open the table
                file_dir = os.path.join(path, inputs["TABLE_ADDRESS"])
                assert os.path.isfile(file_dir), "%s does not exist" %(file_dir)
                with open(file_dir, "r") as table:
                    reader = csv.DictReader(table, delimiter='\t')
                    table_data = [line for line in reader]
                alltables.append(table_data)
        for lt in alltables:
            col_widths = [len(x) for x in table_data[0].values()]
            ncols = len(col_widths)
            table = nodes.table()
            # set the column width specs
            tgroup = nodes.tgroup(cols=ncols)
            table += tgroup
            for col_width in col_widths:
                tgroup += nodes.colspec(colwidth=col_width)
            # add the header
            thead = nodes.thead()
            tgroup += thead
            thead += self.make_row(["T%d" % len(alltables)], [ncols-1])
            h1_text = table_data[0].keys()
            thead += self.make_row(h1_text)
            tbody = nodes.tbody()
            tgroup += tbody
            row = []
            for line in table_data:
                tbody += self.make_row(line.values())
            table_node.append(table)
        return table_node

    def make_all_seq_tables(self, sequence, sequence_dir):
        table_node = table_plot_node()
        alltables = []
        seqtable = []
        table_write = 0
        frame_count = 0
        table_count = 0
        # get the table data from the sequence file and count the frames
        for ts, inputs, outputs in timing_entries(sequence, sequence_dir):
            if 'TABLE_DATA' in inputs:
                table_write += 1
                seqtable.append(inputs['TABLE_DATA'])
                if table_write % 4 == 0:
                    frame_count += 1
            if 'TABLE_LENGTH' in inputs:
                alltables.append(seqtable)
                seqtable = []
                frame_count = 0
                table_write = 0

        for st in alltables:
            table_count += 1
            table_node.append(self.make_seq_table("T%d" % table_count, st))
        return table_node

    def make_seq_table(self, title, data):
        hdr = 'Repeats Condition Position Time A B C D E F Time A B C D E F'
        hdr = hdr.split()
        col_widths = [len(x) for x in hdr]
        ncols = len(col_widths)
        table = nodes.table()
        # set the column width specs
        tgroup = nodes.tgroup(cols=ncols)
        table += tgroup
        for col_width in col_widths:
            tgroup += nodes.colspec(colwidth=col_width)
        # add the header
        thead = nodes.thead()
        tgroup += thead
        thead += self.make_row([title], [ncols-1])
        h1_text = ["#", "Trigger", "Phase1", "Phase1 Outputs", "Phase2",
                   "Phase2 Outputs"]
        h1_more = [None, 1, None, 5, None, 5]
        thead += self.make_row(h1_text, h1_more)
        thead += self.make_row(hdr)
        tbody = nodes.tbody()
        tgroup += tbody
        # Add each row
        for frame in range(len(data) // 4):
            row = []
            # First we get n repeats
            rpt = int(data[0 + frame * 4], 0) & 0xFFFF
            row.append(rpt)
            # Then the trigger values
            trigger = int(data[0 + frame * 4], 0) >> 16 & 0xF
            strings = [
                "Immediate",
                "BITA=0",
                "BITA=1",
                "BITB=0",
                "BITB=1",
                "BITC=0",
                "BITC=1",
                "POSA>=POSITION",
                "POSA<=POSITION",
                "POSB>=POSITION",
                "POSB<=POSITION",
                "POSC>=POSITION",
                "POSC<=POSITION",
                "",
                "",
                ""]
            row.append(strings[trigger])
            # Then the position
            position = data[1 + frame * 4]
            row.append(position)
            # Then the phase 1 time
            p1Len = data[2 + frame * 4]
            row.append(p1Len)
            # Then the phase 1 outputs
            p1Out = (int(data[0 + frame * 4], 0) >> 20) & 0x3F
            for i in range(6):
                row.append(p1Out >> i & 1)
            # Then the phase 2 time
            p2Len = data[3 + frame * 4]
            row.append(p2Len)
            # Finally the phase 2 outputs
            p2Out = (int(data[0 + frame * 4], 0) >> 26) & 0x3F
            for i in range(6):
                row.append(p2Out >> i & 1)
            tbody += self.make_row(row)
        return table

    def make_row(self, data, more_cols=None):
        if more_cols is None:
            more_cols = [None for x in data]
        row = nodes.row()
        for text, more in zip(data, more_cols):
            entry = nodes.entry()
            if more is not None:
                entry["morecols"] = more
            row += entry
            para = nodes.paragraph()
            entry += para
            para += nodes.Text(text)
        return row


def setup(app):

    app.add_directive('timing_plot', timing_plot_directive)

    app.add_node(table_plot_node,
            html=(visit_table_plot, depart_table_plot),
            latex=(visit_table_plot, depart_table_plot),
            text=(visit_table_plot, depart_table_plot))
    app.add_node(sequence_plot_node,
            html=(visit_sequence_plot, depart_sequence_plot),
            latex=(visit_sequence_plot, depart_sequence_plot),
            text=(visit_sequence_plot, depart_sequence_plot))


def visit_sequence_plot(self, node):
    pass


def depart_sequence_plot(self, node):
    pass


def visit_table_plot(self, node):
    pass


def depart_table_plot(self, node):
    pass
