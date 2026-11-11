# Phase 01 — Deterministic RNG + Shuffle + Seeding Policy

This phase introduces a tiny deterministic PRNG so **deck shuffles, AI choices, and scenario reproduction** are stable and testable on TIC-80.

Phase 00 already proved we can generate `game.js` from `src/` and run `node --test`. Phase 01 builds on that foundation.

## Why we need our own RNG

- `Math.random()` is not seedable and is not reproducible by design.
- We want repeatable runs for debugging and unit tests.
- TIC-80 provides time sources we can use later for “release-ish” randomness, but Phase 01 focuses on deterministic dev seeding.

## Decisions locked (from interview)

- PRNG: **xorshift32**
- Dev seeding (MVP): **constant seed in code** (`MC.config.seedBase`)
- Release/random seeding: **deferred** (planned later alongside dev-boot seed UX)
- Cartridge metadata: add **`// saveid: MortgageCrisis`** in generated `game.js` header (future-proofing for `pmem()`)

## Definition of Done

Phase 01 is done when:

- A deterministic PRNG (**xorshift32**) exists and passes tests
- We can compute a **32-bit seed** for the current game from the configured base seed
- A deterministic in-place **deck shuffle** exists and is stable given a seed
- `scripts/build.mjs` injects `// saveid: MortgageCrisis` into `game.js` header
- Seed visibility/overlay is **deferred** until we are actually playtesting and need reproducible bug reports
- `npm test` includes RNG + shuffle tests and passes

## Scope (what we implement)

### 1) Deterministic RNG module

Implement a tiny RNG with a 32-bit state:

- stores state as unsigned 32-bit
- state must never be `0` (if seed resolves to 0, use 1)
- `nextU32()` → unsigned 32-bit int
- `nextInt(n)` → integer in `[0, n)`
- (optional) convenience helpers like `nextBool()` or `pick(array)`

Recommended xorshift32 step (per `nextU32()` call):

- `x ^= x << 13`
- `x ^= x >>> 17`
- `x ^= x << 5`
- keep the internal state as u32 (coerce with `>>> 0` where needed)

Notes:

- Bitwise ops in JS are 32-bit signed, but `>>> 0` coerces back to unsigned.
- Modulo bias is acceptable for our use (shuffle + AI), given the tiny state and game requirements.

### 2) Seed policy

Add helpers:

- compute a u32 seed
- create a new RNG instance from that seed

Rules:

#### Dev (Phase 01 / MVP)

- Seed = `MC.config.seedBase` (wrap as u32)

This gives deterministic, memorable sequences and reproducibility by sharing `seedBase`.

#### Release/random seeding (deferred)

We intentionally keep Phase 01 deterministic. Time-based seeding, seed display, and seed override are planned as part of the dev-boot work (see Phase 12 in `docs/plan.md`).

### 3) Shuffle helper

Implement Fisher–Yates in-place shuffle:

- `shuffleInPlace(arr, rng)`
  - for `i = arr.length-1..1`: swap `i` with random `j in [0..i]`

This will be used later for deck shuffling.

### 4) Config changes

Add config fields:

- `seedBase: 1001` (memorable base seed)

Keep existing:

- screen dimensions

### 5) Seed display in harness (optional)

Phase 01 does not require any UI changes. Optionally, we can print the current seed on the boot screen while developing.

### 6) Build header metadata

Extend `HEADER_LINES` to include:

- `// saveid: MortgageCrisis`

Reason:

- stabilizes future `pmem()` usage across code edits (without relying on code hash)

### 7) Tests

Add deterministic tests using Node `--test`:

- RNG sequence test:
  - for a known seed (e.g. 1), assert first N outputs match frozen expected values
- `nextInt(n)` bounds test:
  - generates many values, asserts all are in range
- Shuffle determinism:
  - given seed X and initial array, shuffled result matches frozen expected permutation

Implementation detail:

- Tests load `src/*.js` via `vm` (reuse the Phase 00 loader style).
- Tests should stub TIC-80 globals used by boot code (`cls`, `print`).

## Notes / future hooks

- Later we can add seed display/override and time-based seeding once we actually start playtesting (planned Phase 12).

## Notes for Phase 02 (rules engine + state)

- Keep `src/*` **TIC-safe** (no `import`/`export`). Use the VM-based test loader to unit test `MC.*` code from Node.
- When Phase 02 introduces new TIC-80 globals in `src/*`, stub them in tests (either via `extraGlobals` passed to `loadSrcIntoVm` or default stubs) so tests stay frictionless.
- `// saveid: MortgageCrisis` is now injected into generated `game.js`. If Phase 02+ starts using `pmem()`, reserve and document a small slot range early (e.g. 0–31) so saves/debug state don’t collide.
- Treat `game.js` as the canonical paste artifact: after any `src/*` change, run `npm run build` before validating behavior in TIC-80.
- Sprite workflow gotcha: keep a dedicated TIC cart with sprite assets; pasting updated `game.js` updates code while preserving sprites.
- Guard against Phase 02 scope creep: Phase 02 should focus on **state + commands + legality + tests**. Keep UI/rendering minimal until the command layer is stable.

