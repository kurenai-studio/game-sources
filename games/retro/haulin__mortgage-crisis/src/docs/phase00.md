# Phase 00 — Repo Workflow + Build Artifact (`game.js`)

This phase sets up a **boring, deterministic** workflow for a TIC-80 JS project where the runtime must be a **single file** (`game.js`) but humans need modular source.

The end result is:

- You edit code in `src/`
- You run `npm run build`
- A paste-ready `game.js` is generated in the repo root (and committed)
- A minimal test (`npm test`) confirms the module bundle can load in Node via `vm` (future unit tests will build on this)

## Constraints (why Phase 00 exists)

- TIC-80 runs a single JS script (no module loader, no filesystem, no imports)
- We still want modularity in git for maintainability
- We want deterministic builds and minimal footguns

## Decisions locked (from interview)

- **Module ordering**: numeric prefixes, lexicographic concat (e.g. `00_`, `01_`, …, `99_`)
- **Namespace**: a single global `MC` object (`var MC = MC || {};`)
- **Generated artifact**: `game.js` is **committed**
- **Phase 00 runtime**: keep a minimal runnable cartridge entry point (`function TIC() { MC.mainTick(); }`)
- **Watcher**: no watch mode in Phase 00 (manual build only)
- **No `import`/`export` in `src/`** (tests will load scripts via Node `vm` and call `MC.*`)
- **Output debug separators** in `game.js`: yes
- **Test runner**: Node built-in `node --test`
- **Phase doc naming**: `docs/phase00.md` (two digits; lexicographic-friendly)

## Definition of Done

Phase 00 is done when:

- `npm run build` generates root `game.js`
- `game.js` begins with TIC-80 headers:
  - `// script: js`
  - `// title: Mortgage Crisis`
- `game.js` contains **exactly one** `function TIC()` definition
- Pasting `game.js` into TIC-80 JS cart runs and shows the boot screen
- `npm test` passes on your machine

## Repository structure to create (Phase 00)

Add these paths (Phase 00 starts intentionally small; later phases fill these out):

- `src/` (source modules; concatenated in numeric-prefix order)
- `scripts/` (build tooling)
- `test/` (Node `--test` suite)
- `package.json` (standardize commands)
- `game.js` (generated output, committed)

## Source code conventions for `src/` (important)

### 1) One global namespace only

- The prelude defines `var MC = MC || {};`
- All other files must attach to it:
  - `MC.config = {...}`
  - `MC.mainTick = function() {...}`

Avoid defining globals like `state`, `ui`, etc. outside `MC`.

### 2) Only one `TIC()`

- `function TIC()` is defined in exactly one module
- Everything else is called from there via `MC.*`

### 3) No ESM syntax in `src/`

The following must not appear in `src/`:

- `import ...`
- `export ...`

We are concatenating scripts, not bundling modules.

### 4) No TIC-80 headers in `src/`

Only the generated `game.js` gets headers like `// script: js`.
Keeping headers out of `src/` prevents accidental duplication.

## Build script spec (exact behavior)

### Inputs

- Read all `src/*.js`
- Sort by filename lexicographically (numeric prefixes provide the order)

### Output

- Write root `game.js`

### Output format

1) Begin with TIC-80 header block:

- `// script: js`
- `// title: Mortgage Crisis`
- Optional generated warning line (recommended):
  - `// generated: do not edit by hand (edit src/* instead)`

2) Then append each module in order with a separator:

- `// ---- <module> ----`
- `<file contents>`
- (newline)

### Guardrails (build should fail with clear messages)

The build script must validate:

- **No `import`/`export`** in any `src/*.js`
- **No `// script:` or `// title:`** lines in `src/*.js`
- **Exactly one** `function TIC(` across all `src/*.js`
  - (We intentionally standardize on `function TIC()` to keep this check robust.)

### Reporting

At the end, print:

- number of input files
- output path
- output byte count

## Minimal runtime stubs

Phase 00 stubs exist only to prove the pipeline works; they are not a long-term pattern. As the project grows, we keep runtime code lean by avoiding defensive fallbacks and enforcing invariants in tests.

## `package.json` (Phase 00)

We keep it dependency-free. It exists to standardize commands:

- `npm run build` → `node scripts/build.mjs`
- `npm test` → `node --test`

Optional (later, not Phase 00):

- `npm run watch` (if we add a watcher)

## Tests (Phase 00 scaffold)

### Purpose

Not to test gameplay yet—just to validate we can load our code in Node in a way that scales to future unit tests.

### Bundle load test spec

The test should:

- Create a Node `vm` context with:
  - `MC` initialized (or allow the prelude to initialize it)
  - stub functions for TIC-80 globals used by boot code:
    - `cls`, `print` (no-op is fine)
- Load every `src/*.js` (same ordering rule as build) into that context
- Assert:
  - `MC` exists
  - `MC.mainTick` exists and is a function
  - `TIC` exists and is a function

This gives us a foundation for future rule-engine tests without requiring ESM exports.

Additionally, we keep a “compiled-style” bundle-load test that concatenates `src/*.js` into one big script (like `game.js`) and runs it in a single VM context to catch load-order / concatenation issues early.

## Git / committing

- `game.js` is generated but **committed**.
- TIC-80 reference docs live under `tic-80-docs/` (API + wiki). Cartridge code should not depend on these; they’re reference-only.

## Verification checklist (manual)

- Run `npm run build`
- Open `game.js` and confirm:
  - headers present at the top
  - separators for each `src/*` file
  - exactly one `function TIC()`
- Paste `game.js` into TIC-80 → confirm boot screen renders
- Run `npm test` → passes

## Handoff to Phase 01

Once Phase 00 is stable, Phase 01 starts by:

- adding deterministic PRNG module under `src/` (still no exports)
- keeping the `src/` layout flat (we concatenate `src/*.js` in lexicographic order), adding new modules under `src/` as needed

