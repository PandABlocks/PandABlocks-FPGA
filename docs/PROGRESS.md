# Docs Rewrite Progress — PandABlocks-FPGA

Tracks every target page for this repo. Update the relevant line **in the same commit** as the file
it refers to. Statuses: ☐ todo · ◐ stub · ✅ converted · 🔍 needs-review · ⛔ blocked (→ issue #).
Page list expanded from `06-source-provenance-map.md`.

## Stage A — scaffold
- ✅ skeleton instantiated (title/github/logo swapped, apidoc + pip-tutorial + run-container removed)
- ✅ TOC + stubs for every target page present (10 how-to/expl/ref stubs + blocks slot + 42 module stubs + 4 landing + index)
- ✅ `index.md` README-include + `how-to/contribute` CONTRIBUTING-include resolve
- ✅ xref/intersphinx wired + cross-link probe resolves in built output (how-to/local-development → PandABlocks-client)
- ✅ module-docs surfacing decided + 42 paths build (out-of-tree pattern; files stay under modules/)
- ✅ `myst build` green (exit 0, no warnings/errors), 59 pages
- ✅ Pages deploy wired — `.github/workflows/docs.yml` switched to `myst build` (copier-aligned)

## §5 module-docs surfacing — DECISION
Prototyped both mechanisms from Stage A spec §5; **both built clean** (42 pages, 0 warnings, files
physically under `modules/`):
- (a) symlink `docs/modules -> ../modules` + `pattern: modules/*/*_doc.md`
- (b) out-of-tree `pattern: ../modules/*/*_doc.md`  ← **CHOSEN**

Chose (b): keeps `docs/` clean (no committed symlink, which avoids checkout/Windows symlink quirks)
while keeping `myst.yml` project root at `docs/` and the 42 files physically beside their `module.ini`.
CI checks out the whole repo (default), so the out-of-tree files are present at build time.

## Tutorials
- (none in v4 — empty `tutorials.md` landing kept for parity; the byte-identical FPGA tutorial copies
  are dropped, preserved under `docs/_legacy_rst/` for now)

## How-to
- ✅ how-to/app — source: reference/app.rst — converted; runtime query note added
- ◐ how-to/block — source: reference/block.rst — partial ("Writing docs" = tooling) [Prompt E]
- ⛔ how-to/testing — source: reference/testing.rst — blocked: verify
- ✅ how-to/cocotb — source: reference/cocotb.rst — converted; IP assumption verify-note kept
- ◐ how-to/build-fpga-image — source: NEW (Interview5 §10) — writable-now
- ◐ how-to/finedelay-test — source: github.io finedelay-test.rst — writable-now
- ◐ how-to/local-development — source: NEW (devcontainer pointer) — writable-now. Holds the Stage A xref probe.
- ✅ how-to/contribute — `{include} .github/CONTRIBUTING.md` — scaffold include resolves

## Explanations
- ◐ explanations/framework — source: reference/framework.rst — partial (needs refresh)

## Reference
- ⛔ reference/blocks — source: blocks.rst (generated listing) — blocked: tooling (MyST generator)
- ◐ modules/*/*_doc.md ×42 — source: modules/*/*_doc.rst — writable-now (mechanical RST→MyST, Stage D)
- ◐ reference/glossary — source: reference/glossary.rst → links to meta-panda canonical — writable-now
- ⛔ reference/vhdl-standard — source: NEW (Interview1 §4) — blocked: author

## Blocked (issues raised)
Issues not yet created — Stage B (Prompt B) will create and link them.
- ⛔ how-to/testing — issue #TBD — verify
- ⛔ reference/blocks — issue #TBD — tooling (MyST block-listing generator)
- ⛔ reference/vhdl-standard — issue #TBD — author

## Notes
- **Legacy sources preserved.** Original Sphinx/RST tree moved to `docs/_legacy_rst/` (not in TOC,
  ignored by `myst build`) so Stage D/E conversion can read sources in-tree; also on `origin/master`.
  Reference screenshots (build_arch/coverage_report/errors_csv/values_table/waveform.png, fpga_arch.png)
  are preserved there for reuse.
- **Default branch is `main`** — publish gated on `main`/tags; redirect to `./main/index.html`.
- **xref/intersphinx prototype.** Only `PandABlocks-client` (deployed) is active; probe in
  `how-to/local-development` resolves in built output. meta-panda + server + devcontainer + fastcs kept
  commented until published; uncomment in Stage F and upstream into python-copier-template.
- **CI** mirrors python-copier-template-example `_docs.yml` (npm+mystmd build, upload-artifact of
  `docs/_build` minus templates cache, versioned move, `make_switcher.py`, peaceiris v4).
