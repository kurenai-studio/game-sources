# 198 — Rebuild level 1 as fourteen waves, one per beat

**Task 1 of phase 11e** · branch `feat/fourteen-beat-level-one` · closes
[#198](https://github.com/LuchoC-Dev/little-spaceship/issues/198)

**This is a candidate, not a result.** The verdict is task 2's and task 5's, and it comes from the
project owner's play session ([#201](https://github.com/LuchoC-Dev/little-spaceship/issues/201)).
Every number below is written as a proposal with the reasoning that produced it, so the session can
move any beat without re-deriving anything. This project has refused arithmetic as a verdict twice,
on 22/08 and 25/08.

## What changed

`assets/data/waves.json` and `assets/data/level-01.json` only, plus the two generated documents
`docs/levels/level-01.md` and `docs/levels/waves.md`. **`assets/data/enemies.json` was not touched**
([#199](https://github.com/LuchoC-Dev/little-spaceship/issues/199) settled those numbers) and neither
was `assets/data/formations.json` — no beat needed a formation the eight existing ones cannot express.
Nothing outside `assets/data/` and `docs/` changed.

- **Fifteen placements over thirteen waves became fourteen placements over fourteen waves.**
  `l1-tank-solo` appeared three times in the old level; it is gone as an id, because a one-spawn
  filler wave placed three times is 11b's mechanical translation of the original 92 rows, not a beat.
- **Every wave id now names its beat**, in the campaign document's own words.
- **All seven shapes of `assets/data/trajectories.json` are now used.** `grep -c trajectory
  assets/data/waves.json` returned 0 before this branch and returns 13 after it. The three shapes
  11c built — `strike-run`, `veer-left`, `veer-right` — appear only through the per-spawn
  `"trajectory"` override, which is the lever 11c added and nothing used.

## The fourteen beats

The beat names are `docs/planning/04-campaign-and-levels.md`, "Level 1 design → Provisional
sequence". Times are from the generated document and were confirmed against a live load (below).

| # | Beat | Wave | Kept / adapted / new | Why |
|---|---|---|---|---|
| 1 | audiovisual introduction | `l1-intro-flyover` | **new** | The beat had no wave at all — the old level opened on `l1-basic-intro` after a bare 8 s offset. Three `enemy-light` overridden onto `dive` streak past at `atX 0.10 / 0.90 / 0.85`, away from the player's own column, and are gone in 3.4 s each. It is set dressing that establishes the invasion, not a fight. |
| 2 | initial calm | `l1-opening-calm` | **new** | Split out of `l1-basic-intro`, whose first two lone basics were doing this job inside a wave named for beat 3. One basic, at 5.0 s into an 8 s wave, at `atX 0.20`: the first alien seen, not yet a threat. Density 0.13/s, the second-lowest in the level by design. |
| 3 | first isolated basics | `l1-first-basics` | **adapted** | 11b's `l1-basic-intro` *is* this beat and its spawn shape is kept intact — single, then `line-3` three times, then `column-3`, and the first `weapon-upgrade` on `line-3` slot 1. What changed is length only: 27.5 s → 14.0 s, and the two lone opening basics moved to beat 2. |
| 4 | light/fast | `l1-light-and-fast` | **adapted** | 11b's `l1-light-intro` is the beat: the light archetype alone, on its own `swoop`, formation by formation. Trimmed 24.0 s → 11.0 s and **every `atX` raised**, which is also the fix for one of the two open Checks findings (below). |
| 5 | combined formations | `l1-combined-formations` | **adapted** | `l1-basic-light-mix` is the beat. Trimmed 26.5 s → 13.0 s, one repeat dropped, `atX` raised on both `swoop` entries. |
| 6 | tanks and shifts in priority | `l1-tanks-and-priority` | **adapted** | Built from `l1-tank-intro-b`, which was already this beat: two tanks arriving among fragile enemies. The three separate `l1-tank-solo` placements are folded away. The shift in priority is the tank's 31 s of `crawl` screen time, per the shape catalogue — the tanks are still on screen through beat 7. Second `weapon-upgrade` here. |
| 7 | super-fast | `l1-super-fast` | **adapted** | `l1-rush-intro-a` and `-b` merged into one beat, and this is the phase's own example sentence made real: the same archetype enters on its default `dive` at 63 s and on `strike-run` at 69 s. `strike-run` bottoms out at `y ≈ 50`, 20 units above `playerStartY 30`, so it commits to the player's band and leaves. |
| 8 | one or two heavy carriers | `l1-heavy-carrier` | **adapted** | `l1-carrier-intro` is the beat. **One** carrier, deliberately, so that beat 11's two read as escalation rather than repetition — the campaign document says "one or two". Trimmed 28.0 s → 13.0 s. At 1000 hp the carrier's `spawner` (interval 4.0 s) now produces children before dying, which is the whole point of #199. |
| 9 | evolved basics/shooters | `l1-evolved-shooters` | **adapted** | `l1-shooter-intro`, trimmed 17.0 s → 10.0 s, with the third `weapon-upgrade` moved here. |
| 10 | high-pressure combinations | `l1-high-pressure` | **new** | `l1-veteran-mix` was a 25 s grab-bag of every archetype including two tanks, which is beat 13's job, not this one. Rebuilt as the catalogue's own prescription for this beat: **both veers crossing under descending basics**, at `atX 0.88` and `0.12`, plus rush columns and a shooter line. Placed at `offset -2.0` so it overlaps beat 9's tail. `extra-life` here. |
| 11 | difficult encounter → attachment | `l1-twin-carriers-attachment` | **adapted** | The decided rule of 21/08, untouched and restated in the id: **two heavy carriers at once, and defeating it delivers the attachment**. `l1-carrier-pair`'s `pair` formation and `attachment` on `dropSlot 0` are kept exactly. What changed is the pressure around them — `strike-run` rushes and a `veer-left` rush instead of `column-3` repeats — which is the catalogue's entry for this beat and `01-vision-and-scope.md`'s rule that difficulty is not health. Placed at `offset -1.5` so it opens while beat 10 is still resolving. |
| 12 | brief rest | `l1-brief-rest` | **kept** | `l1-rest-basic`, unchanged in composition — one basic carrying `bomb-recharge` — shortened 11.0 s → 6.0 s. This is the beat that earns its place or does not, and that is a play question. |
| 13 | final escalation | `l1-final-escalation` | **adapted** | `l1-finale-a` was 41 s and 23 spawns, longer than the whole opening third. Rebuilt at 15.0 s and 12 spawns, keeping its intent — every archetype at once — and adding both veers and a `strike-run`, which the catalogue names for this beat. Its carrier is dropped: two carriers already happened at beat 11 and a third made the finale a repeat. Highest density in the level, 2.13/s, which is where the peak belongs. |
| 14 | boss | `l1-boss-approach` | **new** | See below — this is the one design decision in this branch that is not simply recovering the campaign document. |

## Beat 14 needed a wave, and that is a decision worth arguing

The acceptance criterion is *fourteen waves, one per beat*, and beat 14 is the boss. The boss is not
a wave: it is `boss.entersAt` in `level-01.json`, read by `core/domain/system/BossSystem.java`. Taken
literally there is no fourteenth wave and the level would have thirteen.

`l1-boss-approach` resolves that honestly rather than by counting differently: a 7 s escort — a
shooter line, a light diagonal, a rush column — that starts at exactly `boss.entersAt 139.5`, while
the core descends from `y 310` to `combatY 175` at `entranceSpeed 25`, which takes 5.4 s. The escort
is what the player is fighting while the boss arrives, and it is cleared by the time the boss reaches
combat. **The boss's beat therefore has a wave and the count is fourteen for a reason, not by
bookkeeping.**

The cost is one Checks finding, and it is the intended one — the generator's own words are *"Legal,
occasionally intended, never accidental."* It is named in the Checks list below.

## The two Checks findings the phase inherited: both fixed

Both were `enemy-light` in `diagonal-mirror` on `swoop`, placed far enough left that most of the
swept width sat outside `0 .. 208` — 53% in `l1-carrier-pair`, 63% in `l1-finale-a`. They read in
range at the spawn instant and were not, which is exactly the drift the 11d generator was built to
catch.

**The fix is arithmetic, not judgement, and it generalises.** `swoop` is `vx -10, vy -40`; an
`enemy-light` (radius 4.5) is on screen for `(270 + 4.5) / 40 = 6.9 s` and therefore drifts 69 units
left. For the whole sweep to stay inside the playfield:

| formation | widest slot offset | minimum `atX` | maximum `atX` |
|---|---|---|---|
| `single` | 0 | 0.36 | 0.98 |
| `diagonal` / `diagonal-mirror` | ±15 | 0.43 | 0.90 |
| `vee-5` | ±32 | 0.51 | 0.82 |

Every `enemy-light` spawn in the new content sits inside its row. Nothing else in the level uses a
drifting `constant` shape. The generated Checks section no longer reports either finding, or any
off-screen finding at all.

## What the Checks section still says, and why each one stays

`node tools/build-level-docs.js` was run after every content change and its output is committed.
Three findings remain and all three are deliberate:

- `placement #10 l1-high-pressure has offset -2.0` — the overlap onto beat 9's tail. This is the one
  mechanism the wave format has for producing pressure nothing else can, per
  `core/domain/system/SpawnSystem.java`'s predictive `scheduleChain`, and the check exists to make an
  overlap impossible to write by accident, not to forbid it.
- `placement #11 l1-twin-carriers-attachment has offset -1.5` — the same, opening the difficult
  encounter before the high-pressure beat has finished.
- `boss.entersAt 139.5 is earlier than the last placement's end at 146.5 s` — beat 14, argued above.

**No wave uses `{"type": "cleared"}`, and that is a decision #199 forced.** A `cleared` wave holding
a tank (300 hp) or a carrier (1000 hp) now lasts several times longer than the same wave would have
before #199 merged, and the length of the level would stop being a number anyone can state — the
generated document says so itself: every absolute time after a `cleared` wave becomes a lower bound.
With every wave on `fixedDuration` the whole timeline is exact arithmetic and the play session has a
fixed thing to react to. **If the session wants a beat that waits for the player** — beat 11 is the
obvious candidate — that is a one-line change and it should be made after the session, not before it.

## The length I landed on, and how

**146.5 s of waves, boss entering at 139.5 s.** Not a verdict: task 2 owns the length and it is fixed
by playing.

How it was reached, so the session can move it in one place rather than fourteen. The target is
"around three minutes, boss included" (27/08/2026), against 302 s today. Budgeting backwards: a boss
fight is the remaining ~35–45 s, so the waves get ~145 s. That was distributed across the fourteen
beats by function rather than evenly — the two calm beats and the rest take 19 s between them, the
two carrier beats take 29 s because a carrier at 1000 hp needs the time, and the finale takes 15 s.
Then two negative offsets (−2.0 and −1.5) pull 3.5 s back out at the exact two places where overlap
is the intent anyway.

**Where I was uncertain, and the session should watch:**

- **Beat 6's two tanks at 300 hp each.** 600 hp arrives at 51 s, when the player has just picked up
  the second `weapon-upgrade`; `core/domain/system/WeaponSystem.java`'s `pattern(shotLevel)` fires 3
  parallel projectiles at shot level 3, so that is 200 damage/s of held fire if every projectile
  lands — about 3 s of sustained fire per tank in a 12 s beat. If the tanks read as an interruption
  rather than a priority shift, the beat is too short, not the tanks too tough.
- **Beat 11's two carriers at 1000 hp each.** 2000 hp in a 16 s wave, at shot level 4 (5 projectiles,
  333 damage/s at best). Perfect focused fire kills them in 6 s; real play will be 10–14 s, which is
  most of the wave. **This is the single number most likely to be wrong** and the arithmetic scales
  linearly if it is.
- **The weapon-upgrade schedule moved a lot**: 21.0 / 133.5 / 256.0 s became 16.0 / 51.0 / 89.0 s.
  That is forced by a 146 s level — the third upgrade has to arrive before the difficult encounter or
  the encounter is unwinnable — but it means the player reaches shot level 4 at 89 s, and #199's own
  note applies: **watch-item 1 (`enemy-basic` versus `enemy-shooter`) is answerable only before that
  point**, in beats 3 and 9. Beat 9 at 85 s is deliberately just before the third upgrade for that
  reason.
- **Beat 5 is the densest beat before the finale** at 1.77/s and it arrives at 38 s, when the player
  is still at shot level 2. I stretched it from 11 s to 13 s once for exactly this reason. It may
  still be the hardest moment of the first half.

## What was verified, and how

**The real content loads through the real loader.** A standalone program built against `core.jar`,
`game.jar` and `gdx-1.14.2.jar` constructed a genuine
`game/adapter/content/JsonContentSource.java` over `assets/data/` and walked the placement chain. It
printed all fourteen waves with `start`/`end` matching the generated document row for row, and
`waves end at 146.5`. This matters because `JsonContentSource.requireOnlyKeys` rejects unknown keys —
a `"trajectory"` on a spawn entry either parses or fails loudly — and because the doc generator is a
second implementation of the same parse, not the same one.

**The whole level, boss included, simulates without an exception.** The same program constructed a
real `core/application/Simulation.java` over that content and ticked it 12000 times at 1/60 s — 200 s,
past `boss.entersAt 139.5` and past the last wave's end at 146.5 s. `Simulation.tick` runs the
pipeline unconditionally, with no outcome guard (`Simulation.java:127-134`), so every spawn event in
the level, every `dropSlot` and every trajectory override was actually resolved by
`SpawnSystem.spawnWave`. No exception.

**An incidental measurement worth reporting, because it is the closest thing to a play signal an
agent can produce.** In that run the input frame was a stationary player holding fire at the centre
of the playfield. The outcome was `IN_PROGRESS` at 90 s and `DEFEATED` at 100 s — a do-nothing player
now dies during beats 10 and 11, the high-pressure combination and the twin carriers. Against the
25/08 complaint that the level was too easy that is encouraging, and it is **not** a balance verdict:
a stationary player is not a player, and where a real one dies is what the session is for.

**`./gradlew build`** — BUILD SUCCESSFUL, whole build, `:core:test` green. No test changed and none
needed to: no rule changed in this branch, and no test reads `assets/data/` (`LevelScoreReplayTest`
builds its fixture in-test).

**`node tools/build-level-docs.js`** — run after every content change; `docs/levels/level-01.md` and
`docs/levels/waves.md` are committed in the state it produced, so CI's drift check is clean.

**Not checked:** how any of this looks or feels on screen. `./gradlew :desktop:run` was not used —
the questions it would answer are the play session's, and a screenshot cannot answer them.

## Findings

### For 11d's document contract — the beat map points at a table this branch made stale

`docs/plan/11d-per-level-document/document-contract.md` is where the last round went; this is a third,
beside the two already filed as [#206](https://github.com/LuchoC-Dev/little-spaceship/issues/206).

The generated document's final section, "The beat map", says the mapping from placements to beats
*"exists, written by hand, in `docs/plan/11c-movement-shapes/shape-catalogue.md` under 'What points at
what'"*. That table names `l1-basic-intro`, `l1-tank-solo`, `l1-rush-intro-a`, `l1-veteran-mix`,
`l1-carrier-pair`, `l1-rest-basic` and `l1-finale-a` — **none of which exist any more.** The document
therefore points a reader at a table where every wave id is wrong, and it will keep doing so, because
that section is static prose in `tools/build-level-docs.js` and the catalogue is a closed phase's
decision document that should not be rewritten to track content.

The decision to make the beat map un-generated was right and I am not reopening it. Two cheap fixes,
either of which keeps the pointer honest:

1. **Point at the level's own status fragment instead**, since the beat table is now written per
   rebuild and dated — the table above is the current one.
2. **Or make the section say what it can actually stand behind**: that a wave id is the only place a
   beat is named, that this level's ids do name their beats, and that nothing enforces it. That is
   true, checkable, and does not go stale.

There is a third option worth naming and refusing: adding a `"beat"` field to a wave. It would make
the section generable, and it is a content-format change that `core-domain` owns and that phase 12 is
the right place to weigh, not this one.

### For [#201](https://github.com/LuchoC-Dev/little-spaceship/issues/201), the play session

Beyond the five questions already in `plan.md`, and beyond the four #199 added:

- **Does beat 1 read as an introduction or as three enemies the player failed to shoot?** It is the
  one beat with no equivalent in the old level and the one most likely to be wrong. It is also the
  beat that most wants something `assets/data/` cannot express — see the finding below.
- **Do the veers read at all?** `veer-left` at `atX 0.88` and `veer-right` at `atX 0.12` are the
  catalogue's own prescription, and beats 10, 11 and 13 are the first time in this repository that a
  shape with a horizontal component has been placed deliberately. If they do not move the safe
  corridor, the catalogue already names the fix and refused it on purpose: a `sine` weaving kind, its
  "first candidate to revisit".
- **Does the same `enemy-rush` read as two different threats** on `dive` at 63 s and on `strike-run`
  at 69 s? That sentence is the 11 group's own stated goal and beat 7 is where it is tested.
- **Is beat 12, six seconds long, a rest or a hiccup?** The plan says this is where the rest beat
  earns its place or does not.

### A mechanism this beat wanted and 11b/11c did not build — reported, not added

**A wave cannot be empty.** `JsonContentSource.loadWaves` throws *"wave 'x' has no spawns"* on a wave
with an empty `spawns` array, so beat 1 — *audiovisual introduction* — cannot be expressed as a wave
that occupies time and spawns nothing. Today the only way to buy silent time is a placement `offset`,
which belongs to the level and cannot be named, reused or documented as a beat.

I did not work around it by inventing a "silence" archetype, and I did not ask for a change: beat 1
is served well enough by three harmless fly-bys, and an empty wave is a content-format question with
no beat forcing it beyond this one. It is written here so that whoever designs level 2's opening in
phase 12 does not rediscover it, and so the decision to allow it — or to keep refusing it — is made
once and on purpose.
