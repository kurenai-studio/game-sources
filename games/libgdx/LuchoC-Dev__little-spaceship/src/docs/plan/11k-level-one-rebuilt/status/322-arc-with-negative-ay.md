# 322 — `arcPlayfieldTime` now handles `ay <= 0`

**Branch:** `fix/arc-with-negative-ay`. **Closes:** #322.
`game-presentation`, on `tools/build-level-docs.js` only (the plan's scope exception for `tools/`),
plus this fragment. No shipped document changed.

## What was wrong

`arcPlayfieldTime` assumed `ay > 0` in computing both its "up" root (`-2*vy/ay`, the time to climb
back out of the top by symmetry with the turn) and its "down" root (the quadratic's other root, past
the bottom edge), then returned `Math.min(down, up)`. For `dive-across-left` (`vx: -34, vy: -55, ay:
-22`, `assets/data/trajectories.json`), `up` evaluates to `-5.0` — meaningless, since a negative `ay`
never turns, so there is no climb to time — and `Math.min` picked that negative value over the correct
positive `down` root (`3.12`), which the quadratic had already computed correctly. The negative time
then propagated into `sweptExtent`'s `drift = vx * seconds`, flipping the reported sweep direction, and
into the shapes table's `turns after`/`apex depth` columns, which divide by `ay` directly and produce a
negative time and an inverted (negative) apex for the same reason.

## The fix

`arcPlayfieldTime` now branches on the sign of `ay`, matching what `ArcTrajectoryDefinition`'s own
javadoc says is legitimate for all three cases — none is clamped or rejected:

- **`ay > 0`**: unchanged — turns and may exit either way, `Math.min(down, up)`.
- **`ay < 0`**: returns the quadratic's down root directly, with no `up` term at all. The down root
  is always well-defined here: with `a = ay/2 < 0`, `-4a > 0`, so the discriminant
  `vy^2 - 4a*(270+2r)` is `vy^2` plus a non-negative term and is never negative.
- **`ay = 0`**: the quadratic's own `a = 0` divides by zero, so this is solved as the linear equation
  it actually is — `target / |vy|`, direction-agnostic the same way `screenTime` already treats a
  `constant`'s `vy`. `vy = 0` alongside it (no motion at all) returns `null`, mirroring `screenTime`'s
  own `vy === 0` case.

The shapes table ("Movement shapes this level uses") no longer prints `turns after`/`apex depth` for
`ay <= 0`: both are properties of a shape that pulls out of its dive, which `ay <= 0` never does. It
prints `no turn — never pulls out` / `no apex` instead of a negative time or an inverted depth.

## Hand derivation

`dive-across-left`, `enemy-light` (radius 4.5), `vx: -34, vy: -55, ay: -22`. `target = 270 + 2*4.5 =
279`. `a = -11`. `disc = 55^2 - 4*(-11)*279 = 3025 + 12276 = 15301`, `sqrt(disc) ≈ 123.696`.
`down = (55 - 123.696) / (2*-11) = -68.696 / -22 ≈ 3.1226 s` — matches the issue's own "down = 3.12"
and the tool's printed output on a promoted fixture (below).

Swept extent for the wave placement at `atX 0.85`: `at.min = 176.8 - 4.5 = 172.3`,
`at.max = 181.3`. `drift = vx * 3.1226 = -34 * 3.1226 ≈ -106.17`.
`min = min(172.3, 172.3 - 106.17) = 66.13`, `max = max(181.3, 66.13... ) = 181.3` →
**`66.1 .. 181.3`**, matching the tool's own output. Mirrored `dive-across-right` (`vx: +34`) at
`atX 0.15` gives `at.min = 26.7, at.max = 35.7`, `drift ≈ +106.17`, extent **`26.7 .. 141.9`** — also
matched.

`ay = 0` case, checked by temporarily editing `dive-across-left`'s `ay` to `0` and reverting
(`git checkout -- assets/data/trajectories.json` afterward, confirmed clean): `target = 279`,
`time = 279 / 55 ≈ 5.0727 s`, `drift = -34 * 5.0727 ≈ -172.47`, `min = min(172.3, 172.3-172.47) ≈
-0.2`. The tool printed exactly `-0.2 .. 181.3 **leaves**`, matching.

All three derivations were done by hand before running the tool, then confirmed against its actual
output on `test-light-family` (`assets/data/waves.json`) promoted to a scratch `level-99.json`
(created, generated against, then deleted — never committed).

## What I decided about `ay == 0`

Not an error. `core/port/ArcTrajectoryDefinition.java`'s own javadoc says `ay = 0` "degenerates to the
same numbers a `SimpleTrajectoryDefinition` would give, which the catalogue calls a coincidence of the
maths, not a reason to route a constant shape through this record instead" — so `core` accepts it as
content, deliberately, and `JsonContentSource` does not reject it either (not re-checked here, per this
tool's own stated policy of not reimplementing the real loader's validation). The generator's job is to
describe it correctly, not to second-guess whether it should have been authored as a `constant`. It
degenerates to the same linear arithmetic `screenTime` already uses for a `constant`, so
`arcPlayfieldTime` now does exactly that instead of dividing by zero.

## Whether a shipped document changed

**Neither did.** `node tools/build-level-docs.js --check` prints `unchanged` for both
`docs/levels/level-01.md` and `docs/levels/waves.md`, both before and after this fix, and
`git status --porcelain` at the end of this task shows only `tools/build-level-docs.js` modified.
Level 1 places no negative- or zero-`ay` arc today (task 6, not this one, is what will), and the three
positive-`ay` arcs already placed (`strike-run`, `veer-left`, `veer-right`) produce byte-identical rows,
because the `ay > 0` branch of `arcPlayfieldTime` and the `turnsAfter`/`apexDepth` ternaries are
unchanged for that case.

I deliberately did **not** touch the general prose paragraph below the shapes table ("An `arc` turns
at `-vy / ay` and bottoms out ..."), even though it is no longer the whole story once `ay <= 0` content
ships — adding to it, as I did in an earlier pass, regenerated `docs/levels/level-01.md` (only that
static text moved, no number did) and broke the "must still print `unchanged`" requirement this issue's
"Watch out for" section states literally. The per-row table logic is what the acceptance criteria is
about; the static paragraph is a pre-existing general note that stays accurate for every trajectory
placed in a level today and is not this issue's problem to update.

## Acceptance criteria

- [x] A negative-`ay` arc gets a positive, correct screen time and a swept extent in the direction it
  actually travels, each checked against a hand derivation — above.
- [x] The shapes table says something true for it instead of a negative turn time and an inverted
  apex — `no turn — never pulls out` / `no apex`, shown on the promoted fixture.
- [x] `node tools/build-level-docs.js` still prints `unchanged` for both documents on unchanged
  content — shown above.
- [x] Demonstrated on a fixture the way #310 and #314 were — `test-light-family` promoted to a scratch
  `level-99.json`, wrong on the old code (`git stash` back to it: `-5.0 s`, `172.3 .. 351.3`, negative
  turn/apex), right on the new (`3.1226 s` / `-5.0727 s` for `ay=0`, correct-direction sweeps, `no turn`
  rows) — deleted, never committed.

## What I judged rather than found written down

- **`ay = 0` returns `null` when `vy = 0` too**, rather than `0` or an error — mirrors `screenTime`'s
  own treatment of a motionless `constant`, the closest existing precedent for "this shape never
  reaches the playfield's exit condition."
- **Not updating the static prose paragraph** below the shapes table, to keep the "must print
  `unchanged`" requirement literal rather than "numbers don't move" — see above.
