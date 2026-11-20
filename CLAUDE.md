# CLAUDE.md — ironcalc (lilith fork)

Global rules apply (`~/.claude/CLAUDE.md`). Nix conventions: `.claude/rules/nix.md`.
Read `DESIGN.md` before any structural change. Upstream's own docs (README, crate docs)
describe the engine; this file and DESIGN.md describe the fork.

## Purpose

IronCalc made fast enough for lilith's sheet component: incremental recalculation, Firefox
speed, structural edits; built to WASM and published through lilith_ui_vue's export.

## Status

- **Current** (2026-11-20): clone of upstream main at `f9366200`, our branch `master`
  (no changes to the engine yet). Flake in `nix/` (Rust 1.95 from pinned stable nixpkgs,
  wasm-bindgen-cli 0.2.129 from unstable to match `Cargo.lock`, binaryen, cargo-llvm-cov;
  approved by Luna 2026-11-20). Baseline numbers so far are from the npm build:
  `/home/luna/dev/lilith_ui_vue/develop/sheet-spike-2026-11-20.md`.
- **Target**: DESIGN.md "Work order".
- Anything not listed under Current does not exist yet.

## Git

- `upstream` = github.com/ironcalc/IronCalc, **fetch only** (push URL disabled on purpose).
  Local `main` mirrors `upstream/main`; `master` is ours, rebased onto it.
- `origin` = `git@github.com:luna-niemitalo/ironcalc.git` (Luna's). Luna pushes; Claude
  never pushes (global rule). After a rebase onto upstream, the push needs
  `--force-with-lease`.
- Policy (Luna, 2026-11-20): stay rebasable by default (DESIGN.md "Upstream").

## Boundaries

- Sheet bytes (`fromBytes`), xlsx files, and collaboration diffs (`applyExternalDiffs`)
  enter from outside: the engine parses them; our additions must keep failures as errors,
  never panics.
- The WASM API (`bindings/wasm`) is lilith's contract: any signature change is a lilith
  change too.

## Resume

- **Last state**: fork created, flake written; first `direnv` build of the flake was
  running (checks that nixpkgs' rustc has the wasm32 standard library).
- **Next step**: confirm the toolchain builds `bindings/wasm` for wasm32; write
  `develop/build-wasm.nu`; baseline benchmarks (DESIGN.md "Work order" 1).
- **Hazards**: when upstream bumps `wasm-bindgen` in `Cargo.lock`, the flake's
  `wasm-bindgen-cli_0_2_129` must follow, or the build fails on a version mismatch.
