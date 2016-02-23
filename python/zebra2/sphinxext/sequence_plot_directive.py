import os

from matplotlib.sphinxext import plot_directive
from docutils.parsers.rst.directives import images
from docutils.parsers.rst import Directive, states
from docutils import nodes, statemachine

from zebra2.sequenceparser import SequenceParser
from zebra2.configparser import ConfigParser


parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "..", "..", "tests", "sim_sequences")
config_dir = os.path.join(
    os.path.dirname(__file__), "..", "..", "..", "config_d")


class sequence_plot_node(nodes.Element):
    pass


class table_plot_node(nodes.Element):
    pass


class sequence_plot_directive(Directive):

    has_content = False
    required_arguments = 0
    optional_arguments = 0
    option_spec = {'block': str, 'title': str, 'table': bool, 'nofigs': bool}

    def catch_insert_input(self, total_lines, source=None):
        self.total_lines = total_lines

    def run(self):

        #fill the content code with the options from the directive
        blockname = self.options['block']
        plotname = self.options['title']

        plot_content = [
            "from block_plot import make_block_plot",
            "make_block_plot('%s', '%s')" % (blockname, plotname)]

        # override include_input so we get the result
        old_insert_input = self.state_machine.insert_input
        self.state_machine.insert_input = self.catch_insert_input

        plot_directive.plot_directive(
            self.name, self.arguments, self.options, plot_content, self.lineno,
            self.content_offset, self.block_text, self.state,
            self.state_machine)

        self.state_machine.insert_input = old_insert_input
        plot_node = sequence_plot_node()
        node = sequence_plot_node()

        # do a nested parse of the lines
        self.state.nested_parse(
            statemachine.ViewList(initlist=self.total_lines),
            self.content_offset, plot_node)

        #if it is a sequencer plot, plot the table
        if blockname in ["seq", "pcap"]:
            #get the correct sequence
            fname = blockname + ".seq"
            sparser = SequenceParser(os.path.join(parser_dir, fname))
            matches = [s for s in sparser.sequences if s.name == plotname]
            sequence = matches[0]
            if blockname == "seq":
                table_node = self.make_all_seq_tables(sequence)
                node.append(table_node)
                node.append(plot_node)
            else:
                table_node = self.make_pcap_table(sequence)
                node.append(plot_node)
                node.append(table_node)
        else:
            node.append(plot_node)
        return [node]

    def make_pcap_table(self, sequence):
        table_node = table_plot_node()
        # get our ext names
        cparser = ConfigParser(config_dir)
        # find the inputs that change
        input_changes = []
        data_header = []
        for inputs in sequence.inputs.values():
            for name in inputs:
                if "." in name:
                    input_changes.append(name)
                elif name == "START_WRITE":
                    data_header = []
                elif name == "WRITE":
                    hdr_name = cparser.ext_names[int(inputs[name])]
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
        for outputs in sequence.outputs.values():
            data = outputs.get("DATA", None)
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

    def make_all_seq_tables(self, sequence):
        table_node = table_plot_node()
        alltables = []
        seqtable = []
        table_write = 0
        frame_count = 0
        table_count = 0
        #get the table data from the sequence file and count the frames
        for ts in sequence.inputs:
            if 'TABLE_DATA' in sequence.inputs[ts]:
                table_write += 1
                seqtable.append(sequence.inputs[ts]['TABLE_DATA'])
                if table_write % 4 == 0:
                    frame_count += 1
            if 'TABLE_LENGTH' in sequence.inputs[ts]:
                alltables.append(seqtable)
                seqtable = []
                frame_count = 0
                table_write = 0

        for st in alltables:
            table_count += 1
            table_node.append(self.make_seq_table("T%d" % table_count, st))
        return table_node

    def make_seq_table(self, title, data):
        hdr = 'Repeats A B C D A B C D Time A B C D E F Time A B C D E F'
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
        h1_text = ["#", "Use Input", "Input Val", "Ph1", "Ph1 Outputs", "Ph2",
                   "Ph2 Outputs"]
        h1_more = [None, 3, 3, None, 5, None, 5]
        thead += self.make_row(h1_text, h1_more)
        thead += self.make_row(hdr)
        tbody = nodes.tbody()
        tgroup += tbody
        # Add each row
        for frame in range(len(data) / 4):
            row = []
            # First we get n repeats
            rpt = data[0 + frame * 4]
            row.append(rpt)
            # Then the input use
            inMask = (data[1 + frame * 4] >> 28) & 0xF
            for i in range(4):
                row.append(inMask >> i & 1)
            # Then the input values
            inCond = (data[1 + frame * 4] >> 24) & 0xF
            for i in range(4):
                row.append(inCond >> i & 1)
            # Then the phase 1 time
            p1Len = data[2 + frame * 4]
            row.append(p1Len)
            # Then the phase 1 outputs
            p1Out = (data[1 + frame * 4] >> 16) & 0x3F
            for i in range(6):
                row.append(p1Out >> i & 1)
            # Then the phase 2 time
            p2Len = data[3 + frame * 4]
            row.append(p2Len)
            # Finally the phase 2 outputs
            p2Out = (data[1 + frame * 4] >> 8) & 0x3F
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

    app.add_directive('sequence_plot', sequence_plot_directive)

    app.add_node(table_plot_node, html=(visit_table_plot, depart_table_plot))
    app.add_node(sequence_plot_node, html=(visit_sequence_plot,
                                           depart_sequence_plot))

def visit_sequence_plot(self, node):
    pass

def depart_sequence_plot(self, node):
    pass

def visit_table_plot(self, node):
    pass

def depart_table_plot(self, node):
    pass
