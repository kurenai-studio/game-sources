# 180 — Decide what the per-level document must contain

**Task 1 of [phase 11d](../plan.md).** Owner: `level-designer`. Branch:
`docs/level-document-contract`. Written 31/08/2026, before review.

## What was completed

[`../document-contract.md`](../document-contract.md) — fourteen sections, each naming the JSON fields
it is derived from, the beat it answers, and where it is only partly derivable. Twelve refused
sections with reasons. The bar stated as a test, and answered.

Nothing under `assets/data/` was touched; the issue puts that out of scope and 11b/11c closed those
formats.

## What was decided that the plan did not specify

- **Output path `docs/levels/<levelId>.md`.** The plan said only "under `docs/`". One directory, one
  file per level.
- **The generated document carries no design intent, and says so in one line pointing at
  `docs/planning/04-campaign-and-levels.md`.** The three alternatives — inferring a beat from a wave
  id, adding an optional `"note"` key, a hand-written companion file — are named in section 14 with
  why each was refused. The `"note"` key is recommended to phase 12, not to this one: it is not a
  content-only change, because `JsonContentSource.requireOnlyKeys:431` rejects unrecognised keys.
- **A "checks" section** (13) reporting derived warnings. Not asked for by the plan or the issue. It
  is the part of the document a generator can do and a person reliably will not, and it is the answer
  to the plan's own risk that the document becomes a report nobody designs from.
- **Mechanical constraints on the generator** — no timestamp or hash, deterministic ordering, fixed
  float formatting, loud failure on an unresolved id. All are consequences of task 3's
  regenerate-and-diff check, and a generation date alone would have sunk it.
- **Density is printed and a difficulty rating is refused**, on `01-vision-and-scope.md`'s eight
  pressure axes.

## What is open, and what the next person needs

**Four things `assets/data/` cannot give the document**, in descending cost. This is the phase's
finding and it is the answer the coordinator asked for separately:

1. **Design intent — why a beat exists.** No field, and adding one is a parser change. Section 14.
2. **What each drop kind does** — six constants in `core/domain/system/PickupSystem.java:39-71`, no
   `drops.json`.
3. **The boss's geometry constants** — `core/domain/system/BossSystem.java:140-150`.
4. **The enemy projectile radius and the real `pattern` set** — `EnemyWeaponSystem.java:35,37`.

2, 3 and 4 are one defect three times: a value the level designer designs against lives in `core/` as
a constant, so the generator can only quote it, and the quote can go stale without the CI check
noticing — regenerating produces the same text either way. Mitigation decided here: every glossary
entry names its file in backticks, so #56's `docs-refs` would fail on it if the file moved. The fix is
moving those values into content, and it belongs to whoever next opens `core/`.

**For task 2 (the generator, the coordinator's):** sections 1–13 are the emit list, "Mechanical
requirements on the generator" is the constraint list, and the reuse map in section 5 plus the checks
in section 13 are the two things most likely to be skipped and least likely to be missed by a reader
who has never had them.

**For task 4 (reading the document back, `level-designer`'s):** the contract closes with three
specific things to check, including deliberately breaking a scratch copy of level 1 to see whether
section 13 catches it.

**For task 5 (#56, the coordinator's):** the generated document will be dense with backticked content
ids — `enemy-basic`, `l1-veteran-mix`, `slow-descent` — that look like repository references and are
not. `docs-refs` needs either an exemption for `docs/levels/` or a resolver that accepts a content id
`assets/data/` defines. The second is nearly free once the generator exists and turns `docs-refs` into
a real check on the generated document rather than one it is excused from.

**One thing the contract asks the generator to support that no content uses yet.**
`assets/data/trajectories.json` holds seven shapes since 11c and **no wave points at any of them** —
`grep -c trajectory assets/data/waves.json` returns 0. Section 5 requires the spawn-level
`"trajectory"` override to be resolved and marked from day one, because
[11e](../../11e-level-one-redesigned/plan.md) is what starts using it and a generator that only
handles today's content would need rewriting a phase later.

## Verified

- Level 1's pacing table in section 3 was computed from `assets/data/` with a throwaway Python script
  over `level-01.json`, `waves.json` and `formations.json`: waves end at 298.0 s, the boss enters at
  302.0 s, 261 entities across 15 placements. Every number quoted in the contract comes from that run.
- `grep -c trajectory assets/data/waves.json` → `0`.
- `ls tools/` → `agent-memory-path`, `commit-subject-ok`, `hooks`, `install-hooks`, `pre-pr-check`,
  `status-fragments` — no generator.
- `ls docs/` → `STATUS.md`, `design`, `plan`, `planning`, `sources` — no `levels` directory.
- Field-level claims about what the parser accepts were read from
  `game/adapter/content/JsonContentSource.java`; the spawn, drop, lifetime and boss behaviour from
  `SpawnSystem.java`, `PickupSystem.java`, `LifetimeSystem.java`, `EnemyWeaponSystem.java` and
  `BossSystem.java`, each cited at the line in the contract.
- **Not checked by experiment:** whether an agent can actually design level 2 from the document. No
  generator exists, so "What the document alone is enough for" is reasoning over the section list, and
  it says so. Task 4 is where that gets measured.

---

## Coordinator's correction, 31/08/2026

One number in the refusals table conflated two quantities, and both turn out to be real:

- **92** spawn events in `level-01.json` before phase 11b — `git show d10d644:assets/data/level-01.json | grep -c '"at"'` prints `92`, and the two commits either side of the migration print `92` and `0`.
- **261** entities those events place, summing each spawn's formation `slots` — the figure the row was reaching for, but not the number of rows it described.

The row said "261 spawn events" and "261 rows" while section 3 of the same document said 92. Corrected in place to name both. The refusal itself is unchanged and stands.
