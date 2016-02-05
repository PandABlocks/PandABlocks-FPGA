from docutils import nodes

from docutils.parsers.rst import Directive
from docutils.parsers.rst import directives

import os

from matplotlib.sphinxext import plot_directive

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

        #!?!?!?!MAYBE THIS SHOULD GO IN THE visit_sequence_plot ?
        if 'table' in self.options:
            #insert the table
            print "TABLE", self.options['table']
        else:
            print "NO TABLES"

        self.content = [
            "from block_plot import make_block_plot",
            "make_block_plot('" + blockname + "',"  + plotname+ " )"]

        #call the plot directive directive to insert the plot
        plot_directive.plot_directive(self.name,
            self.arguments,
            self.options,
            self.content,
            self.lineno,
            self.content_offset,
            self.block_text,
            self.state,
            self.state_machine)

        text = '\n'.join(self.content)
        node = sequence_plot_node(rawsource=text, **self.options)

        # self.state.nested_parse(self.content, self.content_offset, node)

        return [node]

def setup(app):

    app.add_directive('sequence_plot', sequence_plot_directive)

    app.add_node(sequence_plot_node, html=(visit_sequence_plot, depart_sequence_plot))

def visit_sequence_plot(self, node):
    #put stuff here to happen before
    self.body.append("SOME TEXT HERE BEFORE\n")
    # self.body.append("======= = = = = = = = = ==== = = = = ==== = = = =")
    # self.body.append("#       Use Inp Inp Val Ph1  Ph1 Out Ph2  Ph2 Out")
    # self.body.append("------- ------- ------- ---- ------- ---- -------")
    # self.body.append("Repeats A B C D A B C D Time A B C D Time A B C D")
    # self.body.append("======= = = = = = = = = ==== = = = = ==== = = = =")
    self.body.append(node.attributes['title']+'\n')

def depart_sequence_plot(self, node):
    #put stuff here to happen after
    self.body.append("SOMETHING APPENDED AFTER")
