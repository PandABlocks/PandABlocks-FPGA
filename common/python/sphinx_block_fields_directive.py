import os

from docutils.parsers.rst import Directive
from docutils import nodes
from .ini_util import read_ini
from .configs import FieldConfig


class BlockFieldsNode(nodes.Element):
    pass


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def make_row(data):
    row = nodes.row()
    for text in data:
        entry = nodes.entry()
        row += entry
        para = nodes.paragraph()
        entry += para
        if isinstance(text, list):
            lb = nodes.line_block()
            para += lb
            for t in text:
                line = nodes.line()
                lb += line
                line += nodes.Text(t)
        else:
            para += nodes.Text(text)
    return row


class BlockFieldsDirective(Directive):

    has_content = False
    required_arguments = 1

    def run(self):
        # parse the ini file
        path = os.path.join(ROOT, self.arguments[0])
        ini = read_ini(path)

        # Create a table node to add things to
        table = nodes.table()

        # Add a group for the columns to live in
        header = ["Name", "Type", "Description"]
        tgroup = nodes.tgroup(cols=len(header))
        table += tgroup
        for x in header:
            tgroup += nodes.colspec(colwidth=len(x))

        # Add a header for the table to the group
        thead = nodes.thead()
        tgroup += thead
        thead += make_row(header)

        # Add a body for the table for the fields to live in
        tbody = nodes.tbody()
        tgroup += tbody

        # Make field rows, adding to the group
        for field in FieldConfig.from_ini(ini, number=1):
            description = field.description
            extra = list(field.extra_config_lines())
            if extra:
                description = [description] + extra
            data = [field.name, field.type, description]
            tbody += make_row(data)

        return [table]


def setup(app):
    app.add_directive('block_fields', BlockFieldsDirective)

