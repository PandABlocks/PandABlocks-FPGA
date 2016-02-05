from docutils import nodes

from docutils.parsers.rst import Directive

from matplotlib.sphinxext import plot_directive

class sequence_plot_node(nodes.Element):

    pass

class sequence_plot_directive(Directive):

    has_content = True

    def run(self):

        pdir = plot_directive.plot_directive(self.name,
            self.arguments,
            self.options,
            self.content,
            self.lineno,
            self.content_offset,
            self.block_text,
            self.state,
            self.state_machine)

        text = '\n'.join(self.content)

        node = sequence_plot_node(rawsource=text)

        self.state.nested_parse(self.content, self.content_offset, node)

        return [node]

def setup(app):

    app.add_directive('sequence_plot', sequence_plot_directive)

    app.add_node(sequence_plot_node, html=(visit_sequence_plot, depart_sequence_plot))

def visit_sequence_plot(self, node):
    #put stuff here to happen before
    self.body.append("SOME TEXT HERE BEFORE")

def depart_sequence_plot(self, node):
    #put stuff here to happen after
    self.body.append("SOMETHING APPENDED AFTER")
