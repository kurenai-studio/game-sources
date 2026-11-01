# 324 — level 1 rebuilt on the new vocabulary

**Branch:** `content/level-one-rebuilt`. **Closes:** [#324](https://github.com/LuchoC-Dev/little-spaceship/issues/324).
`level-designer`, on `assets/data/` (`level-01.json`, `waves.json`, `trajectories.json`,
`enemies.json`), the generated `docs/levels/*.md`, the beat map in
`docs/plan/11c-movement-shapes/shape-catalogue.md`, and this fragment. **`balance.json` was not
touched.**

## What shipped

All **twelve waves rewritten**, same twelve wave ids, **68 spawns**, **134.0 s** of waves with
the boss entering at **134.5 s** — a 0.5 s gap where the old level had 0.0 s. Every wave is
`fixedDuration`; **no `cleared` wave**, so no time in the generated document is a lower bound.

**`assets/data/level-01.json` is byte-identical to before** and that is a result, not an oversight:
the twelve placements, their order and the two negative offsets all survived the rebuild, so the
whole change lives in `waves.json`. It is the split phase 11b made — a level is placements, a wave is
content — paying for itself the first time a level was rebuilt on top of it.

**The seven 11c entries are gone.** `slow-descent`, `swoop`, `dive`, `crawl`, `strike-run`,
`veer-left` and `veer-right` were deleted from `assets/data/trajectories.json` and the four archetype
defaults in `enemies.json` were repointed first. `grep` over `assets/`, `core/`, `game/`, `desktop/`,
`web/` and `tools/` afterwards finds them only in test fixtures that define them inline (they build
their own JSON strings and never read `assets/data`) and in three lines of prose inside
`tools/build-level-docs.js` — see "What I found and did not fix" below.

**Every archetype default is now the simple base of its family**, which is what makes the level's
progression readable in the JSON: a row with no `trajectory` key is the shape the player was taught,
and a row with one is the complication.

| archetype | default was | default is |
|---|---|---|
| `enemy-basic` | `slow-descent` | `settle-descent` |
| `enemy-light` | `swoop` | `cut-across-left` |
| `enemy-shooter` | `slow-descent` | `descend-hold-descend` |
| `enemy-rush` | `dive` | `plunge` |
| `enemy-tank` | `crawl` | `grind-down` |
| `enemy-carrier` | `crawl` | `descend-and-anchor` |

`enemy-light`'s default is the one that carries a constraint: `cut-across-left` needs `atX >= 0.69`
or more than half its sweep is off the left edge. Every spawn that takes the default is at
`atX 0.88` or above; every left-side light names `cut-across-right` explicitly.

## Beat by beat — which wave, and why that shape

The intent the generated document cannot carry. Times are absolute level time.

| # | Beat | Wave | 0.0 → | Why this shape |
|---|---|---|---|---|
| 2 | initial calm | `l1-opening-calm` | 0.0 | Two lone basics on `settle-descent`, nine seconds apart-ish. The whole beat is one sentence: **this falls, slowly, and you can move out of the way.** Nothing else in the level is legible unless this is. |
| 3 | first isolated basics | `l1-first-basics` | 9.0 | `settle-descent` in `line-3` and `column-3` for six seconds, then **`descend-and-step-left`/`-right`** as two singles at 8.5 and 9.5 s. The step is introduced alone, one on each side, with nothing else on screen — the archetype's complication taught the way the archetype was. Carries the first `weapon-upgrade`. |
| 4 | light/fast | `l1-light-and-fast` | 22.0 | `cut-across-left`/`-right` crossing in the middle four times, then **`dive-across-left`/`-right`** at 8.0 and 8.5 s. Same teach-then-complicate order: the straight crossing before the one that steepens into a dive. `enemy-light` has no health, so this beat is about reading a line, not about damage. |
| 5 | combined formations | `l1-combined-formations` | 33.0 | The first beat where the complications are the default rather than the finale: both step shapes and `dive-across-left` fly **under** crossing lights. Density 1.42/s, the first crest of the curve. Carries the `shield`. |
| 6 | tanks and shifts in priority | `l1-tanks-and-priority` | 45.0 | `grind-down` at 0.0 s is on screen for 26.5 s — it is still there at 71.5 s, two beats later, and **that is the beat**: a target you cannot clear becomes a target you choose to ignore. `grind-and-wheel-left` at 5.0 s (`atX 0.80`) then takes the top-right of the screen away for eleven seconds. |
| 7 | super-fast | `l1-super-fast` | 57.0 | `plunge` three times, then **`plunge-and-cut-left`/`-right`** as a pair and **`strike-and-withdraw`** last. The withdraw is the one shape in the level that leaves through the top; it is placed alone, at 7.5 s, so the reversal is the only thing happening. |
| 8 | one or two heavy carriers | `l1-heavy-carrier` | 66.0 | One carrier on `descend-and-anchor`: parked from 68.2 s to 82.2 s, **five children while parked** and two more before it leaves. Density 0.40/s and the lowest-pressure stretch before the rest — the pressure here is the 700-point wall and the stream out of it, not the count. Two lights and a `line-3` cross it so the beat is not a shooting gallery. |
| 9 | evolved basics/shooters | `l1-evolved-shooters` | 81.0 | `descend-hold-descend` three times — the shooter's stationary hold, which is the one thing no basic shape does — then **`advance-the-firing-line`** at 9.0 s, `atX 0.50`, `single`. It holds two firing lines fifty units apart and only then leaves sideways. It is the level's only absolute path and the only place it can be: the entry waypoint is x 104, so `atX 0.50` and `single` are forced. |
| 10 | high-pressure combinations | `l1-high-pressure` | 91.0, **offset -2.0** | Overlapped into the shooters by two seconds on purpose: the `line-5` of basics arrives at 91.0, while `advance-the-firing-line` (spawned 90.0) is still descending towards its first hold at 91.2. Then `dive-across-*` from both sides, a shooter line with the `extra-life`, `plunge-and-cut-*` from both sides, and a `vee-5` of diving lights to close. Density 1.82/s, the second crest. |
| 11 | difficult encounter → attachment | `l1-twin-carriers-attachment` | 100.5, **offset -1.5** | **`anchor-and-traverse-left`/`-right`**, one from each side, half a second apart. They park, then slide toward each other from 108.9 s, then park again — the column the children fall into changes halfway through, and the two of them cross. This is the level's one encounter about position rather than volume. The `attachment` is on the left carrier, and it is only delivered if that carrier dies. |
| 12 | brief rest | `l1-brief-rest` | 114.5 | One basic, one `bomb-recharge`, six seconds. It is a rest **only if the carriers are dead** — they are on screen until ~125.7 s otherwise. That is deliberate and it is the sharpest thing in the level for the play session to judge. |
| 13 | final escalation | `l1-final-escalation` | 120.5 | Every archetype, every complex shape, nothing simple except the two `line-5`s that bracket it. Both `grind-and-wheel`s at 3.0/3.5 s take both top corners; `plunge-harder` at 10.0 s raises rush pressure without adding a shape to learn. Density 2.22/s. |
| 14 | boss | *(no wave)* | 134.5 | Waves end at 134.0 and the boss enters at 134.5. |

Beat 1, the audiovisual introduction, carries no wave and did not before this task either.

## Decisions the plan and the issue did not cover

- **The twin-carrier beat stopped being a `pair`.** `pair` puts two carriers at `atX * 208 ± 44`, and
  `anchor-and-traverse-*` is relative so it *would* have worked — but the two would then traverse in
  the same direction, which is a wider version of one carrier. Two `single` spawns at `atX 0.80` and
  `atX 0.20`, on the shape and its mirror, make them converge. The vocabulary fragment's windows
  (`>= 0.61` left, `<= 0.39` mirror) are satisfied.
- **The rest is 6 s and the carriers outlive it.** Kept rather than lengthened. The alternative was a
  rest long enough for the carriers to fall out on their own, which turns the "difficult encounter"
  into something waitable.
- **A 0.5 s gap before the boss instead of 0.0 s.** One breath. It came out of trimming durations to
  land near 134.5 rather than being aimed at, and it was kept because a boss entering on the same
  frame the last wave ends has nothing to recommend it.
- **Curve shape was tuned twice.** The first draft had `l1-combined-formations` at 1.75/s, denser than
  `l1-high-pressure` at 1.36/s, which reads as the level peaking at second 33. Two `column-3`s in
  beat 5 became `single`s and a `vee-5` was added to beat 10. The curve now rises to a first crest at
  beat 5 (1.42/s), sits at ~0.9/s through the archetype-introduction middle, crests again at beat 10
  (1.82/s), drops to 0.17/s and finishes at 2.22/s.
- **Density is not difficulty and the middle of the level says so.** Beats 6, 7, 8 and 9 all sit
  between 0.40/s and 0.92/s while introducing the tank, the rush, the carrier and the shooter. Their
  pressure is screen occupancy, speed, a spawner and rate of fire — the axes
  `03-game-systems.md` names — and none of it shows in the bar chart.

## What the generator's checks said

`node tools/build-level-docs.js` → `updated docs/levels/level-01.md`, `updated docs/levels/waves.md`.
Both committed.

**No geometry, placement or content finding.** Specifically: no spawn past its wave's duration, no
spawn-instant footprint outside `0 .. 208`, no swept extent over the 50 % threshold, **no `atX`
finding on `advance-the-firing-line`** (#300's check, the one this level is the first content to put
under it), no bad `dropSlot`, no unrecognised drop kind, and no boss-over-wave finding.

The two lines the document prints under **Checks** are the two deliberate negative offsets, `-2.0` on
`l1-high-pressure` and `-1.5` on `l1-twin-carriers-attachment`. The generator emits those as findings
by construction — it reports *what* an overlap is, it does not judge it — and the pre-11k document
printed the same two. **That is what "checks clean" means here**: the list contains only the two
overlaps this task chose.

**25 `**leaves**` markers, and not one was tuned away.** Every one is a shape built to exit sideways:
`cut-across-*` crosses the whole width by definition, `plunge-and-cut-*` turns at the player's height
and goes out the side, `grind-and-wheel-*` sweeps across the top, `dive-across-*` bends out of the
bottom corner, and `advance-the-firing-line`'s last leg is written `{x: 0, y: 160}` — leaving through
the left edge *is* the shape. The marker is an annotation on the "x swept" column, not a finding; the
finding only fires above 50 % outside, and none does.

## What I found and did not fix

Both are outside `assets/data/` and therefore outside this task's scope.

1. **`tools/build-level-docs.js` prints three sentences about shapes that no longer exist.** Line 1058
   emits *"The veers spawn on the side they veer away from — `veer-left` at `atX >= 0.75`…"*
   unconditionally in the "Movement shapes" section, and lines 1320–1323 offer the same advice inside
   a finding message. `veer-left`, `veer-right`, `dive` and `slow-descent` also appear in the schema
   examples at lines 709, 724, 726 and 748. The document therefore still explains a rule for two
   shapes the repository no longer contains. Nothing is *wrong* — the advice is sound, the ids are
   dead — but it is the same class of rot as #208, in generated text this time.
2. **A `constant`'s swept extent is extrapolated past its sideways exit.** `screenTime` is
   `(270 + radius) / |vy|`, the time to fall the whole playfield, so `cut-across-right` at `atX 0.05`
   prints a sweep to **301.3** although it crosses the right edge at ~208 and is removed shortly
   after. It over-reports rather than under-reports, so it cannot hide a real case, and `pathSweep`
   (used for `path`) does bound the exit. Worth knowing before anyone reads those figures as
   positions.

## Verification

- **The whole content set loads through the real loader.** A throwaway `main` constructed
  `new JsonContentSource(new FileHandle(new File("assets/data")), id)` for `level-01` and for seven
  scenario ids in one run: `level-01: placements=12 boss@134.5`, each scenario `placements=1 noBoss`.
  A second program then walked all twelve placements and resolved **68 spawns** through
  `source.enemy`, `source.formation` and `source.trajectory` — `resolved 68 spawns across 12
  placements` — which is what proves no spawn names a deleted trajectory.
- **No archetype flies outside its family**, checked by a script that resolves every level-1 spawn's
  trajectory (override, else the `enemies.json` default) against the six family sets from #324:
  `violations 0`. The shapes actually flown are exactly the vocabulary: basic 3, light 4, shooter 2,
  rush 5, tank 3, carrier 3 — **all twenty entries used, none unused**.
- **The seven 11c ids are gone from `trajectories.json`**, asserted by the same script: the
  intersection with the deleted set is empty.
- **`./gradlew build`** — `BUILD SUCCESSFUL in 2s`, exit 0.
- **CI** — `gh run list` on this branch; see the pull request.
- **Whether the level is any good: not checked, and the project owner's.** The game was not launched.

## What the play session should look for, in order

1. **Beat 12, the "brief rest" at 114.5 s.** If the twin carriers are still alive it is not a rest.
   That is the intended stake and it is the single decision in this level most likely to be wrong.
2. **Beat 6's `grind-down` at 45.0 s**, which is still on screen at 71.5 s. Does an unkillable-feeling
   tank crossing two later beats read as pressure or as clutter?
3. **Beat 9's `advance-the-firing-line` at 90.0 s**, overlapped by beat 10 two seconds later. A
   shooter standing on a fixed line while a `line-5` of basics arrives is the level's densest single
   moment on paper.
4. **Beat 7's `strike-and-withdraw` at 64.5 s** — does leaving through the top read as a decision?
5. **Whether the level is 2.5 minutes of the right shape**: it is 134.5 s to the boss, as asked.

## Corrected by the coordinator after review, before merge

`reviewer` accepted this branch and found two prose slips and one omission. The corrections are the
coordinator's because the worker was already closed. **Prose only — no JSON changed, and the family
rule, the timeline, the carrier arithmetic, the `atX` windows and the beat map all reproduced
exactly.**

**Beat 10's overlap was described with the wrong entity state.** The wave-level `-2.0 s` overlap is
real and correctly reasoned; what was wrong was the claim about where the shooter is when the basics
arrive. Reconstructed absolutely: `advance-the-firing-line` spawns at 90.0 and holds its first line
from 91.2 to 93.7 and its second from 94.95 to 97.45, while the `line-5` spawns at **91.0** — before
the first hold begins, not during the second. The beat is still the level's second crest and the
overlap still does what it was written to do; only the sentence was wrong.

**The `**leaves**` count was 26 and is 25.** `grep -o '\*\*leaves\*\*' docs/levels/level-01.md | wc -l`
on the regenerated, tree-clean document returns 25. The category description was also imprecise: only
the `vee-5`-widened `dive-across-*` placements earn the marker, and the two plain `single` ones do
not, because their swept extents sit entirely inside `0 .. 208`.

**Phase 11e's open carrier finding survives this rebuild and is not mentioned above.** It is recorded
here rather than left to be rediscovered. `enemy-carrier`'s health is still 700 and its
`spawner.interval` still 3.0 — both outside this task's mandate — and the weapon-upgrade schedule that
sets the player's shot level by the twin-carrier beat is essentially unchanged (9.0 / 47.0 / 87.0 here
against 11e's 11.0 / 48.0 / 86.0). So 11e's arithmetic still holds: **under ideal fire at shot level
4 a carrier dies in about 2.1 s against a 3.0 s spawner interval**, and beat 11's carriers can still
die before producing a first child. The rebuild neither fixes nor worsens it. **It is a thing to watch
in the play session**, and it is the second time this specific gap has had to be written down.
