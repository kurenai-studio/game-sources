# #190 — The document named no JSON key, and three checks were blind

**Branch:** `fix/level-document-format-section` · **Closes:** [#190](https://github.com/LuchoC-Dev/little-spaceship/issues/190) · **Written:** 31/08/2026

A defect found while the phase runs, by task 4's read-back
([#186](https://github.com/LuchoC-Dev/little-spaceship/issues/186)). Not a task from the plan.
`level-designer` named six generator changes and made none of them, `tools/` being the coordinator's;
this is the coordinator making them.

**The finding that mattered:** `docs/levels/level-01.md` failed the bar its own contract sets. A
`level-02.json` written from the document alone did not load, because sections 1–14 print values and
never keys — `grep -n dropSlot docs/levels/level-01.md` returned nothing.

## Completed

| Correction | What was done |
|---|---|
| **C1** | A **section 0, "The format"**, before At a glance: annotated JSON skeletons for the level file, `waves.json`, `trajectories.json` and the boss block, with every key, its type, its units, whether it is optional and what it defaults to. It states the three things the document only implied — `offset` is measured from the previous placement's **end**, a negative `offset` **overlaps**, and `atX` is a fraction of playfield width applied to the formation's centre |
| **C2** | The Checks section now always prints **what it checked**, then the findings, then one line on what is still the reader's — whether the level is any good |
| **C3** | `x extent` becomes two columns, `x at spawn` and **`x swept`**, plus a check that fires when the swept extent is mostly outside `0 .. 208`, naming the veer-side rule when a veer is the cause |
| **C4** | The boss check is **no longer guarded by `exact`**, and "At a glance" keeps the `gap between them` row when the chain is inexact, saying it is unknowable rather than dropping it |
| **C5** | **Decided: build it.** `docs/levels/waves.md`, its own file, indexes every wave id with its end condition, spawn and entity counts, archetypes, and every level and time that places it. It flags an **unplaced** wave, which nothing else in the repository would tell you |
| **C6** | One line in the header: `game/LittleSpaceshipGame.java:42` holds `LEVEL_ID = "level-01"`, so which level runs is a code change in `game/`, not content |

C7 was `level-designer`'s own amendment to the contract and needed no code.

## Evidence

**C1 was verified mechanically rather than by reading.** A script extracted the key list from **all ten
`requireOnlyKeys` call sites** in `game/adapter/content/JsonContentSource.java` and checked each against
the generated section 0:

```
trajectory '             all present: id type vx vy
trajectory '             all present: id type vx vy ay
wave file                all present: waves
wave                     all present: id end spawns
wave '                   all present: type seconds
wave '                   all present: type
spawn event              all present: at spawn formation atX drop dropSlot trajectory
level file               all present: boss events waves
wave placement           all present: wave offset
boss block               all present: id entersAt coreHealth podHealth armHealth corePoints podPoints armPoints entranceSpeed combatY patternCooldown spreadProjectileSpeed sweepProjectileSpeed

Every key the parser accepts appears in the generated format section.
```

The first run of that script found two real gaps that the read-back had not: **`trajectories.json` and
the boss block were absent from section 0.** The boss block had been left out deliberately, on the
reasoning that the boss section prints every field — but a reader writing a level file needs the schema
where the schema is, not scattered. Both are in now, and the check passes with no exemption.

**C3 caught two spawns in shipped content**, which is the point of it — neither is hypothetical:

```
- `l1-carrier-pair`: `enemy-light` in `diagonal-mirror` at `atX 0.15` on `swoop` sweeps -56.9 .. 50.7 over 6.9 s in the playfield — about 53% of that width is outside 0 .. 208.
- `l1-finale-a`: `enemy-light` in `diagonal-mirror` at `atX 0.10` on `swoop` sweeps -67.3 .. 40.3 over 6.9 s in the playfield — about 63% of that width is outside 0 .. 208.
```

Both read in range at the spawn instant. **They are reported, not fixed** — `assets/data/` is
`level-designer`'s and level 1's content is [11e](../../11e-level-one-redesigned/plan.md).

**A bug in the first version of C3, caught by looking at the output.** The veer-side note fired for
`swoop`, which is not a veer — the condition was "any shape with a negative `vx`". The catalogue's rule
is about the two `arc` shapes that carry a `vx`, and `swoop` drifts by design. Narrowed to
`type === 'arc'`.

Both documents regenerate idempotently, and `--check` is clean.

## Decided, which the issue did not specify

- **C5 is built rather than deferred.** It serves the contract's bar directly: without it a designer of
  level 2 can neither avoid an id collision nor find a reusable wave. Its own file, so no level's
  document changes when another level does — which is what the contract's refusal of a cross-level
  table was actually about.
- **The arc's window is the playfield, not the safety box.** An arc leaves either downward past the
  bottom edge or back up through the top it came from at `-2·vy/ay`, whichever is first. Being off
  screen horizontally only matters while it is on screen vertically.
- **`outsideFraction` is a fraction of swept width, not of time**, and the document says "of that
  width". A time-weighted figure would be more accurate and the wording would then have to be trusted
  rather than checked.

## Open

- **Nobody has yet written a `level-02.json` from the corrected document and loaded it.** That is the
  issue's own last criterion and it cannot be met here: the person who wrote the generator is not a
  fresh reader, and `game/` has no test suite to load content through
  ([#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19)). The key lists are verified against
  the parser, which is the strongest available substitute. **The real test is 11e**, whose
  `level-designer` writes content against this document for the first time.
- **Section 0's key lists are quoted from Java and regenerating cannot keep them honest**, exactly like
  the `CODE` and `DROP_KINDS` tables. The verification above was run once, by hand, and is not a
  standing check. Same class of rot, same argument for
  [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56).
