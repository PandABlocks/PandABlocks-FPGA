from docutils import nodes

from docutils.parsers.rst import Directive
from docutils.parsers.rst.directives import tables
from docutils import  nodes, statemachine

import os

from matplotlib.sphinxext import plot_directive

from zebra2.sequenceparser import SequenceParser
parser_dir = os.path.join(
    os.path.dirname(__file__), "..", "..", "..", "tests", "sim_sequences")

class sequence_plot_node(nodes.Element):
    pass

class sequence_plot_directive(Directive):

    has_content = False
    required_arguments = 0
    optional_arguments = 0
    option_spec = {'block': str, 'title': str, 'table': bool}

    def run(self):

        #fill the content code with the options from the directive
        blockname = self.options['block']
        plotname = self.options['title']

        plot_content = [
            "from block_plot import make_block_plot",
            "make_block_plot('" + blockname + "', '" + plotname+ "' )"]

        #call the plot directive directive to insert the plot
        plot_directive.plot_directive(self.name,
            self.arguments,
            self.options,
            plot_content,
            self.lineno,
            self.content_offset,
            self.block_text,
            self.state,
            self.state_machine)

        text = '\n'.join(plot_content)
        node = sequence_plot_node(rawsource=text, **self.options)

        #if it is a sequencer plot, plot the table
        if blockname == 'seq':
            #make the header for the table
            hdr = []
            # hdr.append(
            # '======= ======= ======= ==== =========== ==== ===========')
            hdr.append(
                '======= = = = = = = = = ==== = = = = = = ==== = = = = = =')
            hdr.append(
                '#       Use Inp Inp Val Ph1  Ph1 Out     Ph2  Ph2 Out    ')
            hdr.append(
                '------- ------- ------- ---- ----------- ---- -----------')
            hdr.append(
                'Repeats A B C D A B C D Time A B C D E F Time A B C D E F')
            hdr.append(
                '======= = = = = = = = = ==== = = = = = = ==== = = = = = =')

            #get the correct sequence
            fname = blockname + ".seq"
            sparser = SequenceParser(os.path.join(parser_dir, fname))
            matches = [s for s in sparser.sequences if s.name == plotname]
            sequence = matches[0]

            seqtable = []
            table_write = 0
            frame_count = 0
            #get the table data from the sequence file and count the frames
            for ts in sequence.inputs:
                if 'TABLE_DATA' in sequence.inputs[ts]:
                    table_write += 1
                    seqtable.append(sequence.inputs[ts]['TABLE_DATA'])
                    if table_write % 4 == 0:
                        frame_count += 1
            #fill the body with the data from the sequence file
            body = []
            for frame in range(frame_count):
                #get the parameters of the table
                params = self.get_frame_data(seqtable, frame)
                #create the string for the table content
                body.append('{rpt}       '
                            '{inmaska} {inmaskb} {inmaskc} {inmaskd} '
                            '{inconda} {incondb} {incondc} {incondd} '
                            '{p1Len}    '
                            '{p1oa} {p1ob} {p1oc} {p1od} {p1oe} {p1of} '
                            '{p2Len}    '
                            '{p2oa} {p2ob} {p2oc} {p2od} {p2oe} {p2of} '
                            .format(**params))

                # body.append('{rpt}       {inMask}       '
                #             '{inCond}      {p1Len}    '
                #             '{p1Out} {p2Len}    {p2Out}'.format(**params))

            #put the final border on the table
            table = hdr + body
            table.append(
                '======= = = = = = = = = ==== = = = = = = ==== = = = = = =')

            content = statemachine.ViewList(initlist=table)
            #call the table directive with the new table content
            rstTable = tables.RSTTable(self.name,
            self.arguments,
            self.options,
            content,
            self.lineno,
            self.content_offset,
            self.block_text,
            self.state,
            self.state_machine)

            table_node = rstTable.run()
            return[table_node[0]]
        else:
            return [node]

    def get_frame_data(self, table, frame):
        #sort the data into a dictionary
        params = dict()
        params['rpt'] = table[0 + frame * 4]
        params['p1Len'] = table[2 + frame * 4]
        params['p2Len'] = table[3 + frame * 4]
        params['inMask'] = (table[1 + frame * 4] >> 28) & 0xF
        params['inCond'] = (table[1 + frame * 4] >> 24) & 0xF
        params['p2Out'] = (table[1 + frame * 4] >> 8) & 0x3F
        params['p1Out'] = (table[1 + frame * 4] >> 16) & 0x3F
        #get the individual bit params
        inoutparams = {
            'inmaska': params['inMask'] & 1,
            'inmaskb': params['inMask'] >> 1 & 1,
            'inmaskc': params['inMask'] >> 2 & 1,
            'inmaskd': params['inMask'] >> 3 & 1,
            'inconda': params['inCond'] & 1,
            'incondb': params['inCond'] >> 1 & 1,
            'incondc': params['inCond'] >> 2 & 1,
            'incondd': params['inCond'] >> 3 & 1,
            'p1oa': params['p1Out'] & 1,
            'p1ob': params['p1Out'] >> 1 & 1,
            'p1oc': params['p1Out'] >> 2 & 1,
            'p1od': params['p1Out'] >> 3 & 1,
            'p1oe': params['p1Out'] >> 4 & 1,
            'p1of': params['p1Out'] >> 5 & 1,
            'p2oa': params['p2Out'] & 1,
            'p2ob': params['p2Out'] >> 1 & 1,
            'p2oc': params['p2Out'] >> 2 & 1,
            'p2od': params['p2Out'] >> 3 & 1,
            'p2oe': params['p2Out'] >> 5 & 1,
            'p2of': params['p2Out'] >> 5 & 1}
        params.update(inoutparams)
        return params


def setup(app):

    app.add_directive('sequence_plot', sequence_plot_directive)

    app.add_node(sequence_plot_node, html=(visit_sequence_plot, depart_sequence_plot))

def visit_sequence_plot(self, node):
    pass
    #put stuff here to happen before
    # self.body.append("SOME TEXT HERE BEFORE\n")
    # self.body.append(node.attributes['title']+'\n')

def depart_sequence_plot(self, node):
    pass
    #put stuff here to happen after
    # self.body.append("SOMETHING APPENDED AFTER")
