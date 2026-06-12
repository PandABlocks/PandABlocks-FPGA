// MyST plugin: `block_fields` directive.
//
// Replaces the old Sphinx `block_fields` directive
// (common/python/sphinx_block_fields_directive.py). Renders a block's
// Name / Type / Description table from its `*.block.ini`.
//
// Parsing is delegated to the standalone `common/python/block_fields.py` CLI
// (shelled out via `--format json`), so the docs use the same canonical
// configparser-based reading as the firmware build rather than a second,
// JS-side parser. Set the PYTHON env var to choose the interpreter.

import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// Directive args are written relative to the repo root (e.g.
// `modules/counter/counter.block.ini`); this plugin lives in docs/_plugins.
const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const PYTHON = process.env.PYTHON || 'python3';
const RENDERER = path.join(REPO_ROOT, 'common', 'python', 'block_fields.py');

function textCell(value, header = false) {
  const cell = { type: 'tableCell', children: [{ type: 'text', value: String(value) }] };
  if (header) cell.header = true;
  return cell;
}

function row(values, header = false) {
  return { type: 'tableRow', children: values.map((v) => textCell(v, header)) };
}

const blockFields = {
  name: 'block_fields',
  doc: "Render a block's fields from its *.block.ini as a Name/Type/Description table.",
  arg: { type: String, required: true, doc: 'Path to the .block.ini, relative to the repo root.' },
  run(data, vfile) {
    const iniPath = path.resolve(REPO_ROOT, data.arg);
    let fields;
    try {
      const out = execFileSync(PYTHON, [RENDERER, iniPath, '--format', 'json'], { encoding: 'utf8' });
      fields = JSON.parse(out);
    } catch (err) {
      vfile.message(`block_fields: failed to render '${data.arg}': ${err.message}`);
      return [];
    }

    const rows = [row(['Name', 'Type', 'Description'], true)];
    for (const f of fields) rows.push(row([f.name, f.type, f.description]));
    return [{ type: 'table', children: rows }];
  },
};

const plugin = { name: 'PandABlocks block_fields', directives: [blockFields] };
export default plugin;
