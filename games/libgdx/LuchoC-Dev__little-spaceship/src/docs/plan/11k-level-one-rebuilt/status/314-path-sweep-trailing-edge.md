# 314 — `pathSweep`'s horizontal exit now uses the trailing edge

**Branch:** `fix/path-sweep-trailing-edge`. **Closes:** [#314](https://github.com/LuchoC-Dev/little-spaceship/issues/314).
`game-presentation`, on `tools/build-level-docs.js` only (the plan's scope exception for `tools/`),
plus this fragment. No shipped document changed.

## What was wrong

`crossLeg`'s horizontal checks stopped the clock the moment the footprint's **leading** edge (the one
in the direction of travel) first touched a side boundary — `at.min` going left, `at.max` going right
— instead of when the **trailing** edge (the one that clears last) does. `isFullyOffPlayfield` in
`core/domain/system/LifetimeSystem.java` removes an enemy only once *every* pixel of it is off screen
(`x + radius < 0` or `x - radius > width`), i.e. the trailing edge, so the tool was reporting an entity
gone before `core` would ever remove it, and the swept extent's far value was systematically short.

## The fix

Swapped which edge each direction checks, in both `crossLeg` and the "extrapolate the last leg
forever" fallback in `pathSweep`:

- `vx < 0` (leftward): was `at.min + h > 0` / `(0 - (at.min + h)) / vx`, now `at.max + h > 0` /
  `(0 - (at.max + h)) / vx` — the rightmost point is the one still on screen after the leftmost point
  has already crossed `0`.
- `vx > 0` (rightward): was `at.max + h < width` / `(width - (at.max + h)) / vx`, now
  `at.min + h < width` / `(width - (at.min + h)) / vx` — symmetrically, the leftmost point lags behind.

Documented the convention in `crossLeg`'s own javadoc, per the issue's "state the convention" ask.
The vertical checks (top/bottom) were untouched — they already matched `isFullyOffPlayfield` per the
issue's own derivation, and rewriting a correct half alongside the broken one is exactly the
regression the issue warns against.

## Hand derivation

**`descend-and-turn-left`** (`test-path-turn`, `enemy-tank`, radius 10.5, `atX 0.85`, `assets/data/trajectories.json`):
segments `{vx:0, vy:-45, 3.0s}` then `{vx:-55, vy:0, 6.0s}`. Formation `single` (`assets/data/formations.json`),
one slot at `offsetX 0`, so `at.min = 176.8 - 10.5 = 166.3`, `at.max = 176.8 + 10.5 = 187.3`.

Leg 1 is purely vertical (`d` only goes from `0` to `-135`, never reaching `downTarget = -291`) — no
crossing, `h` stays `0`. Leg 2: `vx = -55`, trailing edge is `at.max + h`. Corrected candidate:
`(0 - (187.3 + 0)) / -55 = 3.4055...s`, inside the leg's `6.0s` — valid. `hEnd = -55 * 3.4055 = -187.3`.

`minDrift = min(0, -187.3) = -187.3`, `maxDrift = 0`. Reported extent:
`min = 166.3 + (-187.3) = -21.0`, `max = 187.3 + 0 = 187.3` → **`-21.0 .. 187.3`**, matching the tool's
own output on a copy of `test-path-turn.json` promoted to `level-98.json` (deleted after checking, not
committed). Before the fix this fixture reported `0.0 .. 187.3` and never fired `**leaves**`; after,
it fires.

**`hold-the-line-and-exit`** (`test-hold-line`, `enemy-shooter`, radius 6.5, `atX 0.50`): waypoints
resolve to `{vy:-45, ~1.78s}` (vertical only), a `2.5s` wait, then `{vx:70, vy:0, ~1.4857s}` (the
`104 → 208` leg). `at.min = 97.5`, `at.max = 110.5`.

At the start of the last leg `h = 0`. Corrected candidate (trailing edge for rightward = `at.min`):
`(208 - (97.5 + 0)) / 70 = 1.5786s`, which **exceeds** the leg's own duration (`1.4857s`) — no crossing
within the authored leg, so `pathSweep` falls through to "extrapolate the last leg forever" (the same
branch `core` uses once a path's authored time runs out). At that point `h = 70 * 1.4857 = 104.0`.
Extrapolated candidate: `(208 - (97.5 + 104.0)) / 70 = 0.09286s`, giving `hEnd = 104.0 + 6.5 = 110.5`.

`minDrift = 0`, `maxDrift = 110.5`. Reported extent: `min = 97.5 + 0 = 97.5`,
`max = 110.5 + 110.5 = 221.0` → **`97.5 .. 221.0`**, matching the issue's own "roughly 221" estimate
exactly, and matching the tool's output on a copy promoted to `level-97.json` (deleted after checking).
Before the fix this fixture reported `97.5 .. 208.0` and never fired `**leaves**`.

Both derivations were done by hand before running the tool, then confirmed against its actual output.

## Whether a shipped document changed

**Neither did.** `node tools/build-level-docs.js && node tools/build-level-docs.js --check` prints
`unchanged` for both `docs/levels/level-01.md` and `docs/levels/waves.md` before and after this fix,
and `git status --porcelain` shows only `tools/build-level-docs.js` modified. Level 1 places no `path`
trajectory today (confirmed by `grep` over `assets/data/level-01.json`'s waves — every placed shape is
`constant` or `arc`), so this fix is only observable on fixtures, exactly as the task's "watch out for"
predicted.

## A finding about content, not a bug in this fix

`**leaves**` is now reachable and does fire, on shipped `assets/data/test-*.json` fixtures used as
formation/wave test content (`test-path-mirror`, `test-path-oscillate`, `test-cross` all produce a
`**leaves**` row once promoted to a level and regenerated — none of this is committed, each was
promoted to a scratch `level-96.json`, generated, and deleted). Per the issue's own instruction, this
is reported rather than acted on: these are test fixtures exercising path/mirror/veer shapes on
purpose, not level content that needs tuning, and the threshold itself was not touched.

Also checked for crashes on every other `path`/`mirrorOf`/`waypoints` fixture in the repository
(`test-path-loop`, `test-slide-descend`, `test-sweep-width`, `test-dive-retreat`, `test-path-wait`):
all regenerate cleanly (exit 0), no `TypeError`, no infinite loop.

## Acceptance criteria

- [x] A `path` leaving sideways reports its swept extent from the trailing edge, matching what
  `LifetimeSystem` actually removes on — shown above on both fixtures, matching `isFullyOffPlayfield`'s
  own thresholds.
- [x] `**leaves**` is reachable for a `path`, demonstrated on a fixture — both fixtures above now
  fire it.
- [x] The two fixtures report values a hand derivation agrees with, and the derivation is written down
  — above.
- [x] `node tools/build-level-docs.js` still prints `unchanged` for both documents on unchanged
  content, and no shipped document's numbers moved — shown above, level 1 places no `path` so the
  documents are byte-identical.

## What I judged rather than found written down

- **Which edge is "trailing" for each direction.** Derived from `isFullyOffPlayfield`'s own two
  conditions (`x + radius < 0` for a leftward exit, `x - radius > width` for a rightward one) rather
  than reasoning about "leading"/"trailing" in the abstract — the entity's own removal rule already
  states, per axis, which side of the circle has to clear.
- **Not touching the vertical checks**, per the issue's explicit warning — verified by diff that only
  the four `vx` lines (two in `crossLeg`, two in the extrapolation fallback) changed.
