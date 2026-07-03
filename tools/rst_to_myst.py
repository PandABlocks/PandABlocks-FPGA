#!/usr/bin/env python3
"""Mechanical RST → MyST Markdown converter for PandABlocks-FPGA module docs.

Handles the subset of RST used in modules/*/*_doc.rst files:
  - RST headings (underline-based) → ATX headings (#/##/###)
  - .. block_fields:: path         → :::{block_fields} path\n:::
  - .. timing_plot:: :path: :section: → :::{timing_plot}\n:path:\n:section:\n:::
  - .. image:: path                → ```{figure} path\n```
  - .. note::                      → :::{note}\n...\n:::
  - .. code-block:: lang           → fenced code block
  - .. digraph::                   → mermaid digraph or graphviz code block
  - ``inline code``                → `inline code`
  - :ref:`text <target>`           → text (bare)
  - :ref:`target`                  → target (bare)
  - :term:`text`                   → {term}`text`
  - RST simple tables (=== ===)    → markdown tables
  - RST list-table                 → markdown table
"""

import re
import sys
from pathlib import Path


def detect_headings(lines):
    """Return dict mapping line_index → heading_level for RST underline headings."""
    heading_chars = {}  # char → level assigned so far
    level_counter = [0]
    result = {}
    i = 0
    while i < len(lines) - 1:
        text = lines[i]
        underline = lines[i + 1] if i + 1 < len(lines) else ""
        # RST heading: non-empty text line followed by underline of same length
        if (
            text.strip()
            and underline.strip()
            and len(underline.strip()) >= len(text.strip())
            and len(set(underline.strip())) == 1
            and underline.strip()[0] in "=-~^+`#"
            and not text.startswith(" ")
        ):
            char = underline.strip()[0]
            if char not in heading_chars:
                level_counter[0] += 1
                heading_chars[char] = level_counter[0]
            result[i] = heading_chars[char]
            i += 2
            continue
        i += 1
    return result


def parse_directive(lines, start):
    """Parse a RST directive starting at lines[start].
    Returns (directive_name, argument, options_dict, content_lines, end_index).
    end_index is the first line NOT part of the directive.
    """
    # lines[start] is like ".. name:: arg" or ".. name::"
    m = re.match(r"^(\s*)\.\. (\w[\w-]*)::(.*)$", lines[start])
    if not m:
        return None
    indent = m.group(1)
    name = m.group(2)
    arg = m.group(3).strip()
    i = start + 1
    options = {}
    content = []
    # Parse options (lines starting with :key: value at indent+3)
    option_indent = indent + "   "
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            break  # blank line ends options
        if line.startswith(option_indent):
            opt_m = re.match(r"\s+:(\w[\w-]*):\s*(.*)", line)
            if opt_m:
                options[opt_m.group(1)] = opt_m.group(2)
                i += 1
                continue
        break
    # Parse content (lines indented more than directive)
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            content.append("")
            i += 1
            continue
        if line.startswith(option_indent):
            content.append(line[len(option_indent):])
            i += 1
        else:
            break
    # Strip trailing blank lines from content
    while content and not content[-1].strip():
        content.pop()
    return name, arg, options, content, i


def convert_inline(text):
    """Convert RST inline markup to MyST/Markdown."""
    # ``code`` → `code`
    text = re.sub(r"``(.*?)``", r"`\1`", text)
    # :ref:`text <target>` → text
    text = re.sub(r":ref:`([^<`]+)\s*<[^>]+>`", r"\1", text)
    # :ref:`target` → target
    text = re.sub(r":ref:`([^`]+)`", r"\1", text)
    # :term:`text` → {term}`text`
    text = re.sub(r":term:`([^`]+)`", r"{term}`\1`", text)
    # :class:`text` → `text`
    text = re.sub(r":class:`([^`]+)`", r"`\1`", text)
    # :meth:`text` → `text`
    text = re.sub(r":meth:`([^`]+)`", r"`\1`", text)
    # :attr:`text` → `text`
    text = re.sub(r":attr:`([^`]+)`", r"`\1`", text)
    # :func:`text` → `text`
    text = re.sub(r":func:`([^`]+)`", r"`\1`", text)
    # `text`_ links — just keep text
    text = re.sub(r"`([^`]+)`_", r"\1", text)
    return text


def is_rst_sep_line(line):
    """True if line is a RST simple-table separator (only = and space, ≥2 groups)."""
    stripped = line.strip()
    if not stripped:
        return False
    if re.match(r"^[= ]+$", stripped) and "  " not in stripped.strip("=").strip():
        # Must have at least two = groups separated by spaces
        parts = stripped.split()
        return len(parts) >= 2 and all(set(p) == {"="} for p in parts)
    return False


def parse_rst_simple_table(lines, start):
    """Parse a RST simple table starting at lines[start].
    Returns (markdown_table_lines, end_index) or (None, start) if not a table.
    """
    if not is_rst_sep_line(lines[start]):
        return None, start
    # Find column boundaries from the separator line
    sep = lines[start]
    cols = []
    pos = 0
    while pos < len(sep):
        if sep[pos] == "=":
            end = pos
            while end < len(sep) and sep[end] == "=":
                end += 1
            cols.append((pos, end))
            pos = end
        else:
            pos += 1
    if len(cols) < 2:
        return None, start
    i = start + 1
    rows = []
    header_done = False
    while i < len(lines):
        line = lines[i]
        if is_rst_sep_line(line):
            if rows and not header_done:
                header_done = True
                rows.append(None)  # separator marker
            elif rows:
                i += 1
                break
            i += 1
            continue
        if not line.strip():
            i += 1
            continue
        cells = []
        for (c_start, c_end) in cols:
            cell = line[c_start:c_end].strip() if len(line) >= c_end else line[c_start:].strip()
            # Strip RST line-block marker
            cell = re.sub(r"^\|\s*", "", cell)
            cells.append(cell)
        # Handle continuation of previous row (first cell empty = continuation)
        if rows and rows[-1] is not None and not cells[0]:
            # continuation — append non-empty cells to the corresponding previous cells
            for j, cell in enumerate(cells):
                if cell:
                    sep = "<br>" if rows[-1][j] else ""
                    rows[-1][j] = (rows[-1][j] + sep + cell)
        else:
            rows.append(cells)
        i += 1
    # Build markdown table
    md_rows = []
    ncols_from_header = len(cols)
    for row in rows:
        if row is None:
            md_rows.append("| " + " | ".join("---" for _ in range(ncols_from_header)) + " |")
            continue
        md_rows.append("| " + " | ".join(convert_inline(c) for c in row) + " |")
    # If no separator was found, add one after first row
    has_sep = any(r == "| " + " | ".join("---" for _ in range(ncols_from_header)) + " |" for r in md_rows)
    if not has_sep and len(md_rows) >= 2:
        md_rows.insert(1, "| " + " | ".join("---" for _ in range(ncols_from_header)) + " |")
    return md_rows, i


def convert_rst_to_myst(rst_text, source_path):
    """Convert RST text to MyST Markdown."""
    lines = rst_text.splitlines()
    # Add empty line at end for easier parsing
    if lines and lines[-1].strip():
        lines.append("")

    headings = detect_headings(lines)
    out = []
    i = 0
    # Track lines to skip (underlines of headings)
    skip = set()
    for idx, level in headings.items():
        skip.add(idx + 1)  # underline line

    while i < len(lines):
        if i in skip:
            i += 1
            continue

        line = lines[i]

        # Heading
        if i in headings:
            level = headings[i]
            prefix = "#" * level
            out.append(f"{prefix} {convert_inline(line.rstrip())}")
            i += 1
            continue

        # Blank lines outside directives
        if not line.strip():
            out.append("")
            i += 1
            continue

        # RST comment
        if re.match(r"^\.\. _.*:", line) or re.match(r"^\.\. \[.*\]", line):
            # Skip link targets and footnotes
            i += 1
            continue

        # RST directive
        if re.match(r"^\.\. \w[\w-]*::", line):
            result = parse_directive(lines, i)
            if result is None:
                out.append(convert_inline(line.rstrip()))
                i += 1
                continue
            name, arg, options, content, end = result

            if name == "block_fields":
                out.append(f":::{{block_fields}} {arg}")
                out.append(":::")
            elif name == "timing_plot":
                out.append(":::{timing_plot}")
                if "path" in options:
                    out.append(f":path: {options['path']}")
                if "section" in options:
                    out.append(f":section: {options['section']}")
                out.append(":::")
            elif name == "image":
                alt = options.get("alt", Path(arg).stem.replace("_", " "))
                out.append(f"![{alt}]({arg})")
                if "width" in options:
                    pass  # ignore width for now
            elif name in ("note", "warning", "tip", "important", "caution"):
                out.append(":::{" + name + "}")
                for c in content:
                    out.append(c)
                out.append(":::")
            elif name == "code-block":
                lang = arg if arg else ""
                out.append(f"```{lang}")
                for c in content:
                    out.append(c)
                out.append("```")
            elif name == "digraph":
                # Convert to graphviz code block
                out.append(f"```graphviz")
                out.append(f"digraph {arg} {{")
                for c in content:
                    out.append("    " + c if c.strip() else "")
                out.append("}")
                out.append("```")
            elif name == "automodule":
                # Sphinx automodule — replace with a pointer
                out.append(f"<!-- automodule: {arg} — rendered by Sphinx; see source for API docs -->")
            elif name == "include":
                out.append(f"```{{include}} {arg}")
                out.append("```")
            elif name in ("toctree", "contents", "index", "rubric"):
                # Skip navigation/index directives
                pass
            else:
                # Unknown directive — preserve as MyST generic directive
                out.append(":::{" + name + "}" + (f" {arg}" if arg else ""))
                for k, v in options.items():
                    out.append(f":{k}: {v}")
                for c in content:
                    out.append(c)
                out.append(":::")

            i = end
            continue

        # RST simple table (= === format)
        if is_rst_sep_line(line):
            table_lines, end = parse_rst_simple_table(lines, i)
            if table_lines:
                out.extend(table_lines)
                i = end
                continue

        # RST field list (:key: value at start of line — skip, usually in options)
        if re.match(r"^:[\w-]+:", line) and not line.startswith("  "):
            i += 1
            continue

        # Regular text
        out.append(convert_inline(line.rstrip()))
        i += 1

    # Clean up: collapse 3+ blank lines to 2
    result_lines = []
    blank_count = 0
    for l in out:
        if not l.strip():
            blank_count += 1
            if blank_count <= 2:
                result_lines.append("")
        else:
            blank_count = 0
            result_lines.append(l)

    # Strip leading/trailing blank lines
    while result_lines and not result_lines[0].strip():
        result_lines.pop(0)
    while result_lines and not result_lines[-1].strip():
        result_lines.pop()

    return "\n".join(result_lines) + "\n"


def convert_module_doc(rst_path):
    """Convert a single module _doc.rst to _doc.md."""
    rst_path = Path(rst_path)
    md_path = rst_path.with_suffix(".md")

    rst_text = rst_path.read_text(encoding="utf-8")
    myst_text = convert_rst_to_myst(rst_text, rst_path)

    # Check the existing .md stub header to preserve the page title
    if md_path.exists():
        existing = md_path.read_text(encoding="utf-8")
        # Only overwrite if it's still a stub
        if "TODO — documentation stub" not in existing:
            print(f"  SKIP (already converted): {md_path.name}")
            return False

    md_path.write_text(myst_text, encoding="utf-8")
    print(f"  converted: {rst_path.name} → {md_path.name}")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: rst_to_myst.py <path/to/_doc.rst> [...]")
        sys.exit(1)

    converted = 0
    for path in sys.argv[1:]:
        if convert_module_doc(path):
            converted += 1
    print(f"\nDone: {converted}/{len(sys.argv)-1} files converted.")
