# DESIGN — ironcalc (lilith fork)

What this fork changes in IronCalc and why. The engine's own design is upstream's; this
file covers only the fork. Why IronCalc at all, and the sheet component it serves:
`/home/luna/dev/lilith_ui_vue/develop/sheet-spike-2026-11-20.md`.

## Goals

1. **Incremental recalculation.** An edit recomputes only the formulas that depend on it.
   Upstream re-evaluates every formula in the workbook on every edit
   (`base/src/evaluation.rs` `Model::evaluate`).
2. **Firefox speed.** The npm build ran 5–8× slower in Playwright's Firefox than in
   Chromium. Find where (profile first), then fix.
3. **Structural edits.** Inserting a row at the top of 358k cells took 1.2 s (Chromium).
4. **Lint config** for the workspace (upstream has none).

Size targets come from lilith: up to 702 × 8192 cells; load may exceed 3 s (a
professional tool); interactive edits must not block the page (the engine runs in a
worker; lilith shows a busy state for slow operations).

## Invariants

1. **Incremental equals full.** After any sequence of edits, every value equals what a
   full `evaluate()` from scratch gives. Checked by differential tests: random sheets,
   random edits, compare after each edit. Volatile functions (`NOW`, `RAND`, …) are
   compared with the mock clock (`mock_time` feature) and seeded randomness.
2. **Upstream's tests keep passing**, unchanged. A test we must change is a semantic
   change and gets its own note here.
3. **Errors, never panics,** for anything from outside (bytes, xlsx, diffs, user input).
4. **Measured, not assumed.** Every optimization has a before/after number from the
   benchmarks below; profiles attribute, benchmarks decide.

## Upstream

Policy (Luna, 2026-11-20): **stay rebasable by default.** Changes are focused and live
near what they change; refactor only what the work touches; the big wins (incremental
recalculation) are offered upstream (by Luna). Splitting `model.rs` or a lint sweep would
conflict with upstream's daily work, so they wait or go upstream first.
**Exception:** when something genuinely worth it needs breaking or extensive changes, it
goes on a separate long-lived branch, so `master` stays rebasable.

## Incremental recalculation: approach (not built)

Same shape as node_graph, small and in memory inside the engine (Luna, 2026-11-20):
- nodes are cells, packed to one integer key (sheet, row, column);
- edges "formula X reads Y", indexed both ways: forward (what a formula reads; rebuilt when
  its formula changes) and reverse (who reads a cell; drives recalculation);
- **range nodes**: `SUM(A1:A8192)` is one edge to one range, not 8192 edges; "which ranges
  contain this cell" is an interval lookup kept per column;
- volatile and indirect formulas (`NOW`, `RAND`, `OFFSET`, `INDIRECT`) recompute on every
  evaluation;
- an edit marks its dependents dirty, then dirty formulas are evaluated in dependency
  order; structural edits (insert, delete, move) update the graph rather than rebuild it.
Rejected: a generic graph crate (petgraph and similar): it would hold nodes and edges,
but the range lookup is the part that matters and would be ours anyway.

## Build into lilith

`bindings/wasm` built with cargo for `wasm32-unknown-unknown`, `wasm-bindgen` (exact
version of the lock), then `wasm-opt`. lilith_ui_vue's deploy vendors that output instead
of the npm package, so browsers and välipulikka's engine host (Node, the same files) run
one artifact. Not built yet.

## Work order

1. Baseline: native benchmarks (Rust) and the browser benchmark page (lilith's spike,
   pointed at this build); Luna's Firefox 159 numbers; Firefox profiler traces.
2. Release build settings (LTO, one codegen unit, opt-level 3) and `wasm-opt -O3`.
3. Fewer JS↔WASM crossings: bulk input and read calls (upstream main has
   `getCellsBlock`).
4. Incremental recalculation (above).
5. Structural edits.
6. Lint config.
