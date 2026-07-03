#!/usr/bin/env python
"""Render a block's fields from its ``<block>.block.ini``.

Standalone (no relative imports) so it can be run directly as a command-line
tool *and* be shelled out to from the MyST ``block_fields`` directive
(docs/_plugins/block-fields.mjs). Parsing uses :mod:`configparser`, the
canonical reader for these files, so the docs match the firmware build.

Examples::

    python common/python/block_fields.py modules/counter/counter.block.ini
    python common/python/block_fields.py modules/counter/counter.block.ini --format json
"""
import argparse
import configparser
import json
import sys


def read_fields(path):
    """Return ``[{name, type, description}, ...]`` for each field in the ini.

    The block-level ``[.]`` section is skipped; everything else is a field.
    """
    ini = configparser.ConfigParser()
    if not ini.read(path):
        raise SystemExit("block_fields: cannot read ini file %r" % (path,))
    fields = []
    for section in ini.sections():
        if section == ".":
            continue
        fields.append({
            "name": section,
            "type": ini.get(section, "type", fallback=""),
            "description": ini.get(section, "description", fallback=""),
        })
    return fields


def format_table(fields):
    """Format fields as a simple aligned text table for command-line use."""
    rows = [("Name", "Type", "Description")]
    rows += [(f["name"], f["type"], f["description"]) for f in fields]
    w0 = max(len(r[0]) for r in rows)
    w1 = max(len(r[1]) for r in rows)
    lines = []
    for i, (name, typ, desc) in enumerate(rows):
        lines.append("%-*s  %-*s  %s" % (w0, name, w1, typ, desc))
        if i == 0:
            lines.append("%s  %s  %s" % ("-" * w0, "-" * w1, "-" * 11))
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("ini", help="path to the <block>.block.ini file")
    parser.add_argument(
        "--format", choices=["table", "json"], default="table",
        help="output format: human-readable table (default) or json")
    args = parser.parse_args(argv)

    fields = read_fields(args.ini)
    if args.format == "json":
        json.dump(fields, sys.stdout)
    else:
        print(format_table(fields))
    return 0


if __name__ == "__main__":
    sys.exit(main())
