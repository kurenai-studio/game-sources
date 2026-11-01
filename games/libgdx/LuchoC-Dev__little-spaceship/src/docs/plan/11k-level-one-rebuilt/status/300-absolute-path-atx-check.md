# 300 — an absolutely-authored path is checked against the `atX` it was placed at

**Branch:** `feat/absolute-path-atx-check`. **Closes:** [#300](https://github.com/LuchoC-Dev/little-spaceship/issues/300).
`game-presentation`, on `tools/build-level-docs.js` only (the plan's scope exception for `tools/`),
plus this fragment and the regenerated `docs/levels/level-01.md`.

## What shipped

`SpawnSystem.positionSpawned` puts a formation's anchor at `atX * 208` and an absolutely-authored
path (`waypoints`) only ever adds deltas to that — its first waypoint's `x` is the **authoring
origin**, and the wave's `atX` must reproduce it or the path flies somewhere other than what its own
coordinates describe. Nothing checked this before this task.

**Every resolved `path` now carries an optional `entryX`**, set only when the entry was authored with
`waypoints` (not `segments`, which is written as deltas and has no absolute position):

- `parseTrajectoryEntry` sets `entryX = entry.waypoints[0].x` when `hasWaypoints`.
- `mirrorTrajectory` reflects it across the playfield's own centre — `width - entryX`, **not**
  negation — matching what the shipped mirror pairs already show:
  `descend-and-turn-left`/`-right` sit at `atX 0.85`/`0.15`, and `0.85 + 0.15 = 1.00`. Confirmed on a
  scratch fixture: mirroring `sweep-the-width-and-drop` (`entryX 20.8`) produces `entryX 187.2` and
  requires `atX 0.90`, not `atX 0.10` — a plain negation would have gotten this backwards.
- `fasterTrajectory` (`speedOf`) carries `entryX` through unchanged — scaling speed does not move the
  entry point.
- A `path` authored with `segments`, or a `constant`/`arc`, never gets an `entryX` and the new check
  is silently a no-op for it — there is nothing absolute to compare against.

**The check itself** (`requiredAtX`, wired into section 13's per-spawn loop): for a spawn whose
resolved trajectory has an `entryX`, compare `sp.atX * 208` against `entryX`. Outside tolerance, it
reports the wave, the spawn's archetype, the trajectory id, the `atX` it needs and the `atX` it has:

```
`test-hold-line-bad`: `enemy-shooter` on `hold-the-line-and-exit` is an absolutely-authored path
whose entry waypoint sits at x 104.0, requiring `atX 0.50` — placed at `atX 0.45` instead.
```

It is also resolved once per spawn now (`const t = resolve(...)`, right after `enemy`) and reused by
the swept-extent finding and the `cleared`-wave finding below it, which each used to resolve it a
second time redundantly.

## The tolerance

**`ATX_TOLERANCE_PX = 1.1` screen units**, stated and justified in code next to the constant.

`atX` is authored to two decimal places, so the closest a *correctly* placed `atX` can land to its
required value is bounded by that rounding: half of one hundredth of the playfield width,
`208 * 0.005 = 1.04` units. `1.1` gives that a little headroom for floating-point noise without
approaching the gap a real mistake produces — an `atX` off by even one hundredth (e.g. `0.51` written
for a required `0.50`) is `0.01 * 208 = 2.08` units away, about double the rounding bound. The two
cases are far enough apart that the exact value inside `[1.04, 2.08]` is not load-bearing; `1.1` sits
just past the rounding bound with nothing between it and a real mistake.

## Verification

**Idempotency**, the mechanism that must survive:
```
$ node tools/build-level-docs.js && node tools/build-level-docs.js --check
unchanged  docs/levels/level-01.md
unchanged  docs/levels/waves.md
unchanged  docs/levels/level-01.md
unchanged  docs/levels/waves.md
```
`level-01.md` changed once, from the old code to the new — one line added to the "What was checked"
list, nothing else. Level 1 places no absolute path today, so the checks section fires nothing new.

**The check fires on a deliberately mis-placed fixture and stays quiet on the two shipped absolute
trajectories, exactly as 11j placed them** — none of the following is committed; each fixture was
added to a scratch copy of `assets/data/waves.json`/`trajectories.json` and a scratch `level-99.json`,
generated, checked, then reverted with `git checkout` (`git status --porcelain` is clean on
`assets/data/` throughout):

- `test-hold-line` (the shipped `hold-the-line-and-exit` at `atX 0.50`, entry `x 104`) and
  `test-sweep-width` (`sweep-the-width-and-drop` at `atX 0.10`, entry `x 20.8`): both regenerate with
  **no issues found** — the two absolute trajectories 11j placed agree with the check.
- The same wave with `atX 0.45` instead of `0.50` fires the exact message shown above.
- `mirrorOf` in both directions: a trajectory mirroring `hold-the-line-and-exit` (entry `x 104`,
  symmetric around the centre, so its own required `atX` is unchanged at `0.50`) and one mirroring
  `sweep-the-width-and-drop` (entry `x 20.8`, mirrored to `x 187.2`, requiring `atX 0.90` rather than
  the unmirrored `0.10`) — both stay quiet when placed correctly and both fire when placed at the
  other trajectory's `atX` instead, confirming the reflection and not a plain sign flip.
- `speedOf` on `hold-the-line-and-exit` at `atX 0.50`: quiet — the entry point survives a speed
  multiplier unchanged, as it must.

## What I judged rather than found written down

- **The tolerance's exact value.** The plan asks for it "in units on screen rather than as a bare
  epsilon" and to be justified; derived it from the two-decimal authoring precision rather than
  picking a round number, and picked `1.1` specifically to sit just past the rounding bound (`1.04`)
  with a wide, uncontested gap before a real mistake's smallest possible size (`2.08`).
- **Reflection, not negation, for a mirrored `entryX`.** The plan's own wording ("mirrorOf negates
  horizontal components") describes velocities and deltas, which is correct for those, but an
  absolute *position* mirrors by reflection across the centre. Verified this against the two shipped
  mirror pairs' `atX` values before writing any code, then confirmed it a second time on a scratch
  fixture with a non-symmetric entry point (`sweep-the-width-and-drop`, entry `x 20.8`, not near the
  centre) — `hold-the-line-and-exit`'s entry (`x 104`) is exactly the playfield's centre, so it cannot
  by itself distinguish reflection from negation.
- **Resolving the trajectory once per spawn and reusing it**, rather than adding a fourth
  `resolve(...)` call for this check alone. Small, but it removes one of the two redundant lookups
  section 13 already had (the swept-extent block resolved its own copy inline; the `cleared` block
  resolved a third), rather than adding a fourth of the same kind.

## Acceptance criteria

- [x] A spawn whose trajectory is absolute and whose `atX * 208` is not the entry waypoint's `x` is
  reported, naming the wave, the spawn, the trajectory, the `atX` it has and the `atX` it needs —
  shown above.
- [x] It appears in the document's "What was checked" list — one new bullet, `docs/levels/level-01.md`
  diff shown above.
- [x] The tolerance is stated and justified in units on screen, not a bare epsilon — `ATX_TOLERANCE_PX`
  and its comment, argued above.
- [x] The check fires on a deliberately mis-placed fixture and stays quiet on the two absolute
  trajectories as 11j placed them — shown above, plus mirror/speed derivations of them.

## Not this task

Task 5 and 6 (the rebuilt vocabulary and level 1 itself) — this branch is task 2 only, closing #300,
on top of task 1's (#310) and #314's merged work.
