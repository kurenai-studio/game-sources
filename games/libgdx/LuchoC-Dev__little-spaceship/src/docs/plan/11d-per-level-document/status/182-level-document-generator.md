# #182 — The per-level document generator

**Branch:** `feat/level-document-generator` · **Closes:** [#182](https://github.com/LuchoC-Dev/little-spaceship/issues/182) · **Written:** 31/08/2026

Task 2 of phase 11d, the coordinator's per the running order in [`../plan.md`](../plan.md).

## Completed

`tools/build-level-docs.js` reads `assets/data/` and writes `docs/levels/<levelId>.md`, one file per
level. It emits the fourteen sections
[`../document-contract.md`](../document-contract.md) decided in task 1, in that order, and no others.
`docs/levels/level-01.md` is generated and committed, 535 lines.

Node built-ins only, no third-party dependency, per the precedent `docs/design/atlas/build-atlas.js`
set. It carries `#!/usr/bin/env node` and the executable bit, so `tools/build-level-docs.js` works
directly on a Linux runner as well as through `node`.

`--check` writes nothing and exits 1 if any document would change. That flag is what task 3 wires into
CI; it lives here because the generator is the only thing that knows what the document should be.

## Evidence

**It is idempotent, which is task 3's entire premise:**

```
$ node tools/build-level-docs.js
written    docs/levels/level-01.md
$ node tools/build-level-docs.js
unchanged  docs/levels/level-01.md
$ node tools/build-level-docs.js --check
unchanged  docs/levels/level-01.md
```

**The pacing table it computes matches the one `level-designer` worked out by hand**, in
[`../document-contract.md`](../document-contract.md) section 3, to two decimals across all fifteen
placements — 0.55, 0.88, 1.55, 1.00, 0.90, 0.76, 1.00, 0.56, 0.36, 0.65, 1.36, 0.38, 0.09, 1.88,
1.00 — and the two derivations were independent. So were the totals: 92 spawn events and 261 entities,
which is also what `#131` recorded for the pre-11b level.

The roster reproduces the contract's own claim about `enemy-rush`: `rate 4.0` against 3.4 s of screen
time on `dive` is **one shot per pass**, printed as a column rather than left to be noticed.

**Section 13's checks were tested by breaking the content, not by reading the code.** Four faults were
introduced into a scratch copy of `waves.json` and `level-01.json` and all four were reported:

```
- `l1-basic-intro`: `enemy-basic` in `line-3` at `atX 1.00` occupies 182.5 .. 233.5, outside 0 .. 208. Nothing clamps it.
- `l1-basic-intro`: `dropSlot 5` on `line-3`, which has 3 slot(s). Fatal at spawn time (`SpawnSystem.requireSlotInRange`).
- `l1-basic-intro`: a spawn at 99.0 s never fires — the wave ends at 27.5 s. `SpawnSystem.spawnDue` only advances the cursor while the wave is active.
- placement #6 `l1-rush-intro-a` has `offset -6.0`, overlapping `l1-tank-intro-b` by 6.0 s.
```

**The `cleared` path was tested the same way**, by making one wave `{"type": "cleared"}`. The document
switched At a glance to `the waves end at | unknowable`, marked every later row `>=`, and rewrote the
boss paragraph to say the gap is unknowable rather than printing one. That is the single place the
contract warned a generated document could lie by rounding a decision away, and it does not.

Against today's real content the section prints **No issues found**, and the content was restored
byte-for-byte afterwards — `git status` showed nothing modified under `assets/data/`.

## Decided, which the contract did not specify

- **The bar in the curve is scaled to the densest placement of that level, not to a fixed absolute.**
  So it compares beats within one level and never between two. A fixed scale would have made level 2's
  document redraw when level 1 changed, which is the cross-level coupling the contract's refusals list.
- **A spawner archetype's children are in the roster** even though no wave names them, because
  `enemy-carrier` produces `enemy-basic` and a designer reading the roster needs to see what is
  actually on screen.
- **The generator resolves and dies; it does not validate.** `game/adapter/content/JsonContentSource.java`
  is the parser and this is the second reader. An unresolvable id stops the run with the id and the
  context, rather than printing a blank.

## Open

- **The quoted `core/` constants are the known weak point and it is by design.** The values in the
  `CODE` and `DROP_KINDS` tables at the top of the generator are copied from `MotionSystem`,
  `SpawnSystem`, `EnemyWeaponSystem`, `PickupSystem` and `BossSystem`. Regenerating cannot catch a
  drift there — the output is identical whether or not the Java still says it. Each one names its file
  in backticks, which is the mitigation [`../document-contract.md`](../document-contract.md) chose and
  which [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) would enforce. The fix is
  moving those values into content, and it belongs to whoever next opens `core/`.
- **Section 14 is a stub pointing elsewhere**, which is what the contract decided. Design intent has
  no field in `assets/data/` and cannot be generated.
- The CI check is [#183](https://github.com/LuchoC-Dev/little-spaceship/issues/183), the next task.
