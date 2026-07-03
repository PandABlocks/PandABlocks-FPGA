// MyST plugin: `timing_plot` directive.
//
// Replaces the old Sphinx `timing_plot` directive
// (common/python/sphinx_timing_directive.py). Renders a timing diagram from a
// section of a `*.timing.ini` by shelling out to the standalone CLI in
// `common/python/timing_plot.py` (invoked as a module so its relative imports
// resolve), then references the resulting SVGs as files.
//
// Light + dark SVGs are rendered (one Python process, one matplotlib import)
// into `docs/_build/timing/` and referenced with source-relative URLs, which is
// the resolution myst supports for these out-of-tree module pages: it copies
// and content-hashes them into the built site (no data-URI bloat, browser
// cacheable, BASE_URL-safe). The two images are emitted with Tailwind
// `dark:hidden` / `hidden dark:block` classes so the book theme swaps them with
// the page's light/dark mode.
//
// The filename is a hash of the ini content + section + xlabel, so an unchanged
// plot is reused (no re-render) — this is what keeps `myst start` rebuilds cheap
// when editing a single case.
//
// Set the PYTHON env var to choose the interpreter (needs matplotlib).

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const PLUGIN_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(PLUGIN_DIR, '..', '..');
const PYTHON = process.env.PYTHON || 'python3';
// Rendered SVGs live under the build dir (gitignored, browser copies served
// from here). Persists across builds so it doubles as a render cache.
const OUT_DIR = path.resolve(PLUGIN_DIR, '..', '_build', 'timing');

const timingPlot = {
  name: 'timing_plot',
  doc: 'Render a PandABlocks timing diagram from a section of a *.timing.ini.',
  options: {
    path: { type: String, required: true, doc: 'Path to the .timing.ini, relative to the repo root.' },
    section: { type: String, doc: 'Section of the ini to plot (default: the first).' },
    xlabel: { type: String, doc: 'x-axis label.' },
  },
  run(data, vfile) {
    const { path: iniPath, section, xlabel } = data.options;

    let iniContent;
    try {
      iniContent = fs.readFileSync(path.resolve(REPO_ROOT, iniPath), 'utf8');
    } catch (err) {
      vfile.message(`timing_plot: cannot read ini '${iniPath}': ${err.message}`);
      return [];
    }

    // Hash the ini *content* (+ section + xlabel) so editing the ini re-renders.
    const key = crypto.createHash('sha1')
      .update([iniContent, section ?? '', xlabel ?? ''].join('\0')).digest('hex').slice(0, 16);
    const lightFile = path.join(OUT_DIR, `${key}.svg`);
    const darkFile = path.join(OUT_DIR, `${key}.dark.svg`);
    const tablesFile = path.join(OUT_DIR, `${key}.tables.json`);

    if (!fs.existsSync(lightFile) || !fs.existsSync(darkFile) || !fs.existsSync(tablesFile)) {
      fs.mkdirSync(OUT_DIR, { recursive: true });
      const args = ['-m', 'common.python.timing_plot', iniPath,
        '--out', lightFile, '--dark-out', darkFile, '--tables-out', tablesFile];
      if (section) args.push('--section', section);
      if (xlabel) args.push('--xlabel', xlabel);
      try {
        execFileSync(PYTHON, args, {
          cwd: REPO_ROOT,
          env: { ...process.env, MPLBACKEND: 'Agg' },
          encoding: 'utf8',
        });
      } catch (err) {
        vfile.message(`timing_plot: failed to render '${iniPath}'${section ? ` [${section}]` : ''}: ${err.message}`);
        return [];
      }
    }

    const srcDir = path.dirname(vfile.path);
    const alt = section || iniPath;
    const nodes = [
      { type: 'image', url: path.relative(srcDir, lightFile), alt, class: 'dark:hidden' },
      { type: 'image', url: path.relative(srcDir, darkFile), alt, class: 'hidden dark:block' },
    ];
    // Some modules (pcap/seq/pgen) carry data tables alongside the diagram.
    for (const table of JSON.parse(fs.readFileSync(tablesFile, 'utf8'))) {
      nodes.push(tableNode(table));
    }
    return nodes;
  },
};

// Convert a {head, body} table (rows of [text, colspan] cells) to a MyST table.
function tableNode(table) {
  const toRow = (cells, header) => ({
    type: 'tableRow',
    children: cells.map(([text, colspan]) => {
      const cell = { type: 'tableCell', children: [{ type: 'text', value: String(text) }] };
      if (header) cell.header = true;
      if (colspan > 1) cell.colspan = colspan;
      return cell;
    }),
  });
  return {
    type: 'table',
    children: [
      ...table.head.map((r) => toRow(r, true)),
      ...table.body.map((r) => toRow(r, false)),
    ],
  };
}

const plugin = { name: 'PandABlocks timing_plot', directives: [timingPlot] };
export default plugin;
