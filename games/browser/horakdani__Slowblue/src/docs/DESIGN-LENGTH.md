# Length, and what a section is allowed to ask

> **Status: measured history, and the standing record of how the campaign got its size.**
> The decisions here are in force; the *plan* in §§1–7 is not a to-do list, because it was
> carried out (§11) and §§8–10 record what playing it changed. This file **supersedes**
> the section counts and act lengths in [DESIGN-ASCENT.md](DESIGN-ASCENT.md). The campaign
> is **432 sections and 144 authored minutes** (about 108 as played), with act I frozen at
> ten minutes; the 182 sections and 72 minutes in §1 are the "before" column, kept as the
> measurement the rebuild answered. The numbers in §1 and §11 are dated snapshots:
> `tools/stations.sweep.ts` prints today's (instant; it is also part of `npm run sweep`). Further reading:
> [README.md](../README.md) for the game, [IMPLEMENTATION_NOTES.md](../IMPLEMENTATION_NOTES.md)
> for how it is built.

Decided 2026-08-14. The circuit is an hour, and the hour is not the problem — the
*distribution* of it is. This file is the measurement that says so, the four decisions
taken off the back of it, the arithmetic those decisions force, and the one act that has
to prove the whole thing before the other six are touched.

It sits next to [DESIGN-ASCENT.md](DESIGN-ASCENT.md), which is where the acts got their
seven rhythms. Nothing here reopens those rhythms; it changes how much of each there is.

**The circuit is 144 authored minutes now — about 108 as played — and §11 is the table.**

Read in this order. §§1–7 are the plan and act V's first pass. **§8 and §10 are what
happened when it was played**, twice, and they are the two most useful sections here: the
first playthrough came back *"not harder, and not longer"* — both true, and only one of them
a fault; the second came back with something neither pass had looked for, that **the fall
was free**, and had been in every falling act since the campaign turned over. §9 is act V's
second pass, §11 is the other six acts, and §12 is the part that is not done: **nobody has
played any of it.**

## Contents

- [1. What the campaign measures today](#1-what-the-campaign-measures-today)
- [2. What was decided](#2-what-was-decided)
- [3. The arithmetic these force](#3-the-arithmetic-these-force)
- [4. The station's new shape: two movements, and the rest moves to the middle](#4-the-stations-new-shape-two-movements-and-the-rest-moves-to-the-middle)
- [5. The four demands, and what each cost](#5-the-four-demands-and-what-each-cost)
  - [Motion is a modifier, not an alphabet](#motion-is-a-modifier-not-an-alphabet)
  - [The threat that returns is not in the pilot, and why](#the-threat-that-returns-is-not-in-the-pilot-and-why)
- [6. The pilot, as built](#6-the-pilot-as-built)
- [7. What the pilot measured, including the part that says the plan was wrong](#7-what-the-pilot-measured-including-the-part-that-says-the-plan-was-wrong)
  - [The completion criterion is met, and it is still the wrong instrument](#the-completion-criterion-is-met-and-it-is-still-the-wrong-instrument)
  - [Where the pilot landed](#where-the-pilot-landed)
- [8. The pilot was played, and both halves of the verdict were right](#8-the-pilot-was-played-and-both-halves-of-the-verdict-were-right)
- [9. The second pass: four demands, and the length that came with them](#9-the-second-pass-four-demands-and-the-length-that-came-with-them)
  - [What it measured, and the instrument it broke](#what-it-measured-and-the-instrument-it-broke)
  - [What the second pass deliberately did not do](#what-the-second-pass-deliberately-did-not-do)
- [10. Then it was played again, and the fall turned out to be free](#10-then-it-was-played-again-and-the-fall-turned-out-to-be-free)
  - [The instrument that could not see it, and why](#the-instrument-that-could-not-see-it-and-why)
  - [The fix is the medium's, and three reasons it is not the camera's](#the-fix-is-the-mediums-and-three-reasons-it-is-not-the-cameras)
  - [`Medium.drag`: the air has a speed, and outrunning it burns](#mediumdrag-the-air-has-a-speed-and-outrunning-it-burns)
  - [The measurement that says it is a demand and not a rail](#the-measurement-that-says-it-is-a-demand-and-not-a-rail)
  - [Act VI already had a price on its fall, and it is called the course](#act-vi-already-had-a-price-on-its-fall-and-it-is-called-the-course)
  - [The restart budget stopped being a constant](#the-restart-budget-stopped-being-a-constant)
  - [...and the warning that had never been drawn](#and-the-warning-that-had-never-been-drawn)
- [11. It was done six more times, and this is the circuit](#11-it-was-done-six-more-times-and-this-is-the-circuit)
  - [...and the fall's price had to be re-measured, because the rebuild moved it](#and-the-falls-price-had-to-be-re-measured-because-the-rebuild-moved-it)
- [12. What this cost, and what is left](#12-what-this-cost-and-what-is-left)
- [13. Not reopened here](#13-not-reopened-here)

## 1. What the campaign measures today

Estimated act time is `Σ station px / (worldSpeed · pace)` — `World.speed()`, without
`pressure` and `ringEase`, which pull in opposite directions and roughly cancel. Density
is obstacle sections per minute; `open` sections are not obstacles.

This table was assembled by hand, which was fine once and wrong by the second act rebuilt.
It is `tools/stations.sweep.ts` now — the same arithmetic, every station in the campaign,
in about a millisecond, printed by `npm run sweep`. Run that rather than trusting the
numbers below, which are what the campaign measured on **2026-08-14, before any of this**.

| act | est. time | sections | obstacle | obst/min | narrowest gap | hunters |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| I · The Deep | 10.0 min | 42 | 35 | **3.5** | 0.26 | 3 |
| II · Flight | 7.7 min | 36 | 29 | **3.8** | 0.28 | 3 |
| III · The Thinning | 10.2 min | 20 | 13 | 1.3 | 0.22 | 0 |
| IV · Orbit | 11.4 min | 18 | 12 | 1.1 | 0.24 | 0 |
| V · The Fallback | 10.9 min | 24 | 18 | 1.6 | 0.24 | 0 |
| VI · The Rain | 9.7 min | 24 | 17 | 1.7 | **0.36** | 0 |
| VII · The Homecoming | 12.1 min | 18 | 5 | 0.4 | — | 0 |
| **total** | **72 min** | **182** | **129** | 1.8 | | **6** |

Three readings, and only the third is a fault:

1. **Every act keeps its ten minutes, and `tests/geometry.test.ts` holds it there** — but
   the ten minutes are filled nine times more thinly at one end of the circuit than at the
   other. Acts I and II ask something every seventeen seconds. Act IV asks every
   fifty-five.
2. **The thinness is authored, not sloppy.** Act III opens on a long empty arrival, act IV
   on a long fall, act VII dilates to a stop. Filling those silences would delete the
   reason each is a separate act. Length must come from somewhere else.
3. **There is no difficulty arc across the circuit.** The narrowest gap sits at 0.22–0.28
   in every act that has gaps, and act VI's is *wider* (0.36) than the trench floor's. All
   six hunters in the campaign are in acts I and II, so the only moving threat in the game
   disappears a quarter of the way in and never returns. The campaign peaks in act II.

## 2. What was decided

* **The first full circuit should run about 2 to 2.5 hours**, from 72 minutes.
* **The forty-two stations stay.** The new minutes go *inside* them: a station roughly
  doubles, from ~1.7 min to ~3.2 min. No eighth act, no station renumbering, no second
  harder lap — one campaign, one curve.
* **The difficulty comes from four new demands**, not from narrower gaps: a gap that
  opens and closes on the breath, a mass that drifts while you approach, two gates close
  enough that the second is set up before the first, and a threat that returns in every
  act. Precision was explicitly *not* chosen: the swarm's own lateral reach is a hard
  floor under gap width, and tightening toward it is the cheapest and most frustrating
  difficulty there is.
* **The free acts get harder too, in proportion.** Acts I and II are what the purchase is
  decided on, so they show the game that is being bought. *(Since then: there is no
  purchase. The game has no monetisation of any kind, so "free" meant only "the first
  two acts", and the reasoning survives as: the opening is what a stranger judges the
  whole game by.)*
* **One act is built first and measured** before the other six are touched.

## 3. The arithmetic these force

**`pace` is frozen, so length is pixels.** The game is not supposed to get faster — that
is decided (DESIGN-ASCENT §5, and act I is the metronome the other six are heard
against). With speed fixed, `+63 minutes` is `+85 000 px` of authored course: roughly a
doubling of everything in `src/config/*.ts`.

**Density is capped by pace, and that cap is the whole design problem.** Obstacles per
minute is `speed / spacing`, and `spacing` is a *spatial* quantity — how much course is
between two obstacles is also how many of them are on screen at once. Act V's deorbit
station runs at 23 px/s; at its authored 850–1120 px spacing that is one obstacle every
37 to 48 seconds, and pulling the spacing in far enough to reach act I's 3.5 per minute
would stack two obstacles inside one screen height in the slowest water in the game.

So the back half of the circuit **cannot be made denser**, and trying is the wrong
solution:

> Length comes from more sections. Difficulty comes from what a section asks. In the slow
> acts these are different levers, and only the second one is available.

There is one exception, and it is free: **the slow stations are thin partly because a
quarter of their sections are `open`.** Act V's deorbit is 2.9 minutes long and carries
two obstacles; two of its four sections are empty water. Spending an `open` costs no
spacing and no pace — it is the only way a slow station gets denser without stacking.

## 4. The station's new shape: two movements, and the rest moves to the middle

A doubled station that is twice as much of the same thing is a station that drags. So the
doubled station is **A, a breath, and B**: A speaks the act's established language, B is
where that station's hardest question arrives, and the empty section between them is the
one place the player can put the phone down mid-station.

The breath is not a new section type and does not cost length: **most act V stations
already end on an `open`, and that rest moves from the end of the station to its middle.**
Two things follow, and the second is a risk rather than a benefit:

* the arrival at the next station is immediate, which raises pressure at exactly the seam
  where a station is named and the banner comes up; and
* the handover between stations loses its landing. Whether that reads as momentum or as
  being shoved is not a thing a test can answer — it goes on the playthrough list in §7.

**Doubling is an average, not a rule.** Act V's stations run from 0.8 min (plasma) to
2.9 min (deorbit) today; doubling each in place would give a 5.8-minute deorbit carrying
four obstacles, which is worse than what exists. The stations **even out to ~3.2 minutes
each**: the short dense one gains duration, the long empty ones gain content.

That number is also the price of failure. From act III on, a lost station begins again,
so station length *is* the punishment, and this change doubles it — at the same time as
the course gets harder. The two multiply. That is the single biggest risk here, it was
taken knowingly, and §7 makes it a measured number rather than a matter of opinion.


**§4 is where the plan was wrong, and the correction is in §7.** The rest did not move; it
was joined. Read §7 before authoring another act to this shape.

## 5. The four demands, and what each cost

The campaign has seven alphabets of six shapes, and the six are the same six *demands* in
seven materials (`levels.ts`, the `SectionSpec` header). These add rows to that table.

| demand | what the hand does | in act V's material | cost |
| --- | --- | --- | --- |
| **two gates, one line** | lay the current for the second gate before entering the first | two shocks ~400 px apart, gaps offset | authoring only |
| **a gap on the breath** | wait, then commit — timing, for the first time | shock diamonds: the standoff distance breathes | one engine mechanism |
| **a mass that drifts** | aim where the gap *will* be | a tumbling piece of the vehicle, walking laterally | the same mechanism |
| **a threat that returns** | hold a shape while something hunts it | a fragment that ablates slower and overtakes | **not built — see below** |

### Motion is a modifier, not an alphabet

The plan above priced the two moving demands as **two new `kind`s in each of the seven
alphabets** — fourteen silhouettes, fourteen builders, fourteen sets of paint. That was
the wrong shape twice over: it is a month of work, and it would have made "the gap moves"
a property of six specific rocks rather than something the game can say about any of the
seventy shapes it already draws.

`MotionSpec` is one optional field on `SpecBase` instead. Any section of any kind can
carry `{ kind: 'aperture' | 'drift', reach, period }`, and a pulsing `veil` in the upper
air or a walking `boulder` in the brook now costs one line each. Two rules hold it up and
both are in `tests/motion.test.ts`:

* **What is authored is the worst case.** An `aperture` is authored *shut* and only ever
  opens, so the corridor sweep — which builds a course and never advances a clock — is
  already checking the hardest phase.
* **A `drift` is swept.** Its authored position is the middle of its travel, so
  `Section.envelope` carries the union of everywhere it ever is and the sweep reads that
  (`hitSwept`). The envelope circles are padded by the sagitta between samples, because a
  row of discs at spacing `d` misses a lens `d²/8r` deep between each pair — two or three
  pixels against a four-pixel sweep cell, invisible in every test and wrong in the one
  direction that matters.

Four things had to be got right, and three of them were not in the plan:

* **The clock is the simulation's, not the breath's.** `World.breathTime` is wall-clock —
  it runs on over a pause so the picture and the audio never drift from the player's own
  breathing — and geometry driven by it would move while the game was paused and would not
  replay from a seed. The period is still the breath's eleven seconds.
* **The pivot is the hole, not the centroid.** An `aperture` pushes its circles away from
  a pivot, and the obvious pivot — the geometry's centroid — is wrong the moment a gap is
  off-centre: a wall with its hole at 0.34 has a short run to the left and a long one to
  the right, so the centroid sits out in the long run and every circle between the hole
  and it is told to move *inward*. The gap would have closed on the one phase the sweep
  never looks at. It finds the widest space between consecutive circles instead.
* **The silhouette cache had to stop being a bug.** `stoneMasses` caches a hull per blob
  for the life of a run and `RockPaint` seeds its surface detail from position, so a
  moving rock would have been drawn where it used to be *and* boiled while it moved. A
  moving blob carries `hx`, its home; the mass is built at home and `paintStone`
  translates the canvas by `massShift`. Nothing else in the file changed and every still
  rock in the game takes the `dx === 0` path.
* **Lateral only.** Nothing about the motion touches y, which is what keeps `lineY`,
  `minY`/`maxY`, `entryY`/`exitY`, the pruning, the cull line and the split-and-re-form
  window all exactly as true of a walking rock as of a still one.

### The threat that returns is not in the pilot, and why

`HunterSpec` is generic and `PredatorSystem` would carry it, but the renderer picks the
silhouette off the medium: `air` gets a raptor and everything else gets a shark. **A shark
at two hundred kilometres is precisely the image the anvil's eleven-kilometre ceiling
exists to prevent.** Act V's hunter is a piece of the vehicle that ablates more slowly than
the swarm and overtakes it burning — a third predator silhouette, with its own commit
tell, not a `hunters: []` entry. It is the next task and it is deliberately not a rushed
one. Three of the four demands are in the pilot; this one is named as missing.

## 6. The pilot, as built

Act V: **24 sections → 57, 10.9 minutes → 20.7, 1.6 obstacles a minute → 2.2.** The `pace`
of all six stations is byte-for-byte what it was.

| station | pace | before | after | obst/min |
| --- | ---: | --- | --- | ---: |
| deorbit | 0.34 | 4 sec / 2 obst / 2.9 min | 7 / 4 / 3.8 | 1.0 |
| nightside | 0.40 | 4 / 3 / 2.2 | 8 / 6 / 3.5 | 1.7 |
| auroraBelow | 0.48 | 4 / 3 / 1.7 | 9 / 7 / 3.2 | 2.2 |
| plasma | 0.70 | 4 / 4 / 0.8 | 15 / 14 / 3.1 | 4.5 |
| meteordust | 0.56 | 4 / 3 / 1.3 | 11 / 9 / 3.5 | 2.5 |
| nucleus | 0.50 | 4 / 3 / 2.1 | 7 / 5 / 3.6 | 1.4 |
| **act** | | **24 / 18 / 10.9** | **57 / 45 / 20.7** | **2.2** |

Six apertures, four drifting masses, three couplets, and 28 compulsory rings against the
old 18 — which is **fewer per minute**, 1.37 against 1.65, for the reason in §7.

## 7. What the pilot measured, including the part that says the plan was wrong

**The baseline, taken before any edit** (`npm run sweep`, 2026-08-14, 24 sections):
`careful` 11/11 in 423 s with 0.73 restarts; `flick` 2/11.

**The first build of the pilot failed, hard.** 0/11 on the sweep, 63 restarts a run, the
bot reaching 15.5 of 52 sections. Every failure was `sweptAway` — not a missed ring, not
an emptied swarm; the swarm was being left behind.

**Motion was not the cause.** The same act with every `motion` stripped measured 19.2
restarts against 18.4 with it. That is the first thing worth knowing about the new axis:
it made no measurable difference to how hard the act is to fly.

**Two things were, and they were both in §4.** Measured one at a time, on the same seeds:

| variant | finished | restarts |
| --- | ---: | ---: |
| the old act (control) | 5/5 | 1.2 |
| the pilot as first authored | 2/5 | 35.6 |
| + no compulsory ring on a station's last demand | 2/5 | 15.4 |
| + a rest at the end of each station | 0/5 | 42.6 |
| **+ both** | **4/5** | **6.8** |

A station's pressure ramp peaks at the station's own end. A compulsory ring asks the swarm
to stop and hold still. Those are opposite demands, and the old four-section stations
never collided them *because every one of them happened to end on empty medium.* §4 read
that rest as spare and moved it to the middle. It was not spare — it is where the swarm
pays back the ground the pressure ramp takes. So:

> **A station ends on a rest, and its last demand is not a gate.** The doubled station has
> two rests, one in each half, and the mid-station breath is an addition rather than a
> move.

That rule cost the plasma half of a written claim. "No breath anywhere in it" was true of
a station of four sections and forty-eight seconds; held to at fifteen sections it was
worth two completions in seven. It has no rest in its *middle* — fourteen demands in a
row — and then it lands.

### The completion criterion is met, and it is still the wrong instrument

§7 of the plan asked for ≥8 of 11 completions on `finish.sweep.ts`. **The fixed act
measures exactly that: `careful` 8/11, 1384 s, 47.7 of 57 sections, 29.73 restarts, score
24 805** against the baseline's 11/11, 423 s and 20 095. The criterion passes.

It is still the wrong instrument, and the reason is not that it is hard — it is that it is
not *comparable*. The sweep's own header says the scripted hand has never been able to fly
a long act, and the numbers bear it out. Measured, unchanged, shipped:

| act | sections | finished | restarts | per section |
| --- | ---: | ---: | ---: | ---: |
| VI · The Rain | 24 | 5/5 | 2.0 | 0.083 |
| V · The Fallback, before | 24 | 7/7 | 1.0 | 0.042 |
| I · The Deep | 42 | 1/5 | 50.6 | 1.20 |
| II · Flight | 36 | 0/5 | 145.4 | 4.04 |

Act II is the act this repo is proudest of and the bot cannot fly it at all. So "8 of 11"
tells us the act is flyable and tells us nothing about whether it now sits where it should
relative to the acts on either side of it — which is the actual question a rebuild asks,
six more times.

**So the comparable criterion is a rate, and it lives in `tools/length.sweep.ts` now**:
restarts per section, which holds still when an act's length changes. The shipped campaign
spans 0.08 to 4.0. A rebuilt act should land inside that span, above the act it replaces,
and well below act I. Keep both: `finish.sweep.ts` answers *can it be flown*, this answers
*where does it sit*.

### Where the pilot landed

| | before | after |
| --- | ---: | ---: |
| finished (`finish.sweep.ts`, 11 seeds, 39 min budget) | 11/11 | **8/11** |
| restarts per section (`length.sweep.ts`, 7 seeds, 30 min cap) | 0.042 | **0.338** |
| finished, same harness | 7/7 | 5/7 |
| run length ÷ authored length | 0.65 | 1.01 |

Eight times the old act V, four times act VI, three and a half times *easier* than act I
and twelve times easier than act II. The last row is the replay cost stated in a unit that
does not move when the act does: a competent hand used to out-run act V's forced drift and
finish in two thirds of its authored length, and now finishes in about exactly it. The
plan asked for no worse than double the baseline's 19 % replay; this is 36 % against a
38 % ceiling.

The two harnesses disagree on restarts — 29.7 against 19.3 — and the disagreement is the
budget rather than the act: a run given thirty-nine minutes to finish keeps trying, and one
capped at thirty gives up. Compare like with like, which is what the rate column is for.

All three measured criteria pass — criterion 2 on its own terms, and then again on the
rate that replaced it. **Criterion 4 — one playthrough on the phone — is the veto, and it
was exercised.** It has been flown, it did not pass, and §8 is what it said. Three things
were on the watch list, because they are what the plan traded away: whether the
mid-station rest reads as a breath or as an interruption; whether the plasma at three
minutes with no middle is the peak of the act or an endurance test; and whether a lost
station at three and a half minutes is a setback or the end of the evening. **None of the
three is what came back.** What came back was that the act was longer and no harder, which
was not on the list at all — and which every number in this section is consistent with.

Also unverified: **nothing has yet looked at a moving obstacle on a screen.** The
translate-the-canvas path in `RockPaint` is covered by typecheck and by the fact that every
still rock takes the `dx === 0` branch, and by nothing else.

## 8. The pilot was played, and both halves of the verdict were right

The first pass was flown end to end on the phone. The report was two sentences — **it is
not harder, and it does not take longer** — and neither of them contradicts §7. They are
what §7 does not measure.

**"It does not take longer" is arithmetic.** Act V is one act in seven. Doubling it took
the campaign from 72 authored minutes to 82, and the player does not experience authored
minutes: `World.pressure` adds up to 55 % to the forced drift across a station, so a
competent hand runs a station in roughly three quarters of its authored length. Fifty-six
real minutes became about sixty-two. **Six minutes on an hour is inside the noise of how
well one evening goes.** Nothing was wrong with the pilot; the pilot is a seventh of the
answer and was reported as if it were the answer.

**"It is not harder" is a design fault, and it is the one worth having found.** Every
section the first pass added was another instance of a shape the act already had — another
shock, another sheet, another plume. That is more act V. It is not a harder act V, and the
sweep could not see the difference because restarts-per-section rises with length whether
the length is new demands or repetitions. Measured: the first pass went from 0.042 to
0.338 restarts a section, and about all of that is that there is more course to fall
behind on.

> Length is sections. Difficulty is what a section asks. The first pass bought the first
> with the second's budget and reported the receipt as both.

## 9. The second pass: four demands, and the length that came with them

| | before | first pass | second pass |
| --- | ---: | ---: | ---: |
| sections | 24 | 57 | **73** |
| obstacles | 18 | 45 | **60** |
| authored minutes | 10.9 | 20.8 | **26.5** |
| obstacles a minute | 1.6 | 2.2 | **2.3** |
| moving sections | 0 | 12 | **17** |
| hunters | 0 | 0 | **5** |

**The ember.** §5 named "a threat that returns" and shipped without it, for a reason that
was correct: the renderer picked its silhouette off the medium, so act V would have been
given the water's shark at two hundred kilometres. That is fixed at the root — `PredatorForm`
is a property of the predator, written by the level author and carried from the spawn, and
the two `medium.kind === 'air'` branches in `Renderer.ts` are gone. Act V's threat is a
piece of the vehicle with a worse mass-to-area ratio than the swarm has: it ablates more
slowly, sheds less speed, and comes up from behind with the air in front of it white. It is
always a stoop. It does not steer, so its commit tell is not a posture — a shark stiffens
and a falcon folds, and **an ember's shock cap goes white**, because the only thing it can
do is arrive. `render/Ember.ts`.

**The scissor.** Two walking masses on one clock and opposite halves of it. One walking mass
asks you to aim where the gap will be; a pair walking against each other means there is no
phase at which either is where you last saw it. It cost one optional field —
`MotionSpec.phase` — and it is safe for the reason a single drift is: the sweep reads the
union of everywhere each mass ever goes.

**The counter-phase pair.** The couplet's demand moved from space into time: two breathing
gaps two breaths apart, the second shut while the first is open. Taking the first the moment
it opens arrives at the second at its narrowest. It is the only place in the campaign where
being early is a mistake.

**The breath halved**, once, at the peak: the same eleven seconds counted twice, so the open
half of the cycle is 2.75 s instead of 5.5. Not a second rhythm — the same bar with eighths
in it.

And two shapes that were simply missing. Orbit's `hulk` had never been authored anywhere in
the campaign and was carried as an explicit exemption in `tests/geometry.test.ts`; it is in
the deorbit now, which makes act V's quiet opener the second place in the act where the body
can be split for pay. The nucleus gets a last `wisps`, met where being scattered has stopped
costing anything.

### What it measured, and the instrument it broke

`tools/length.sweep.ts`, seven seeds, 2026-08-14:

| act V | sections | finished | restarts | /section | run ÷ authored | carriers taken |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| before any of this | 24 | 7/7 | 1.0 | 0.042 | 0.65 | 0 |
| first pass | 57 | 5/7 | 19.3 | 0.338 | 1.05 | 0 |
| **second pass** | **73** | **5/7** | **19.7** | **0.270** | **1.53** | **157** |

Read the fourth column on its own and the second pass made act V *easier*. That is the
finding, and it is about the instrument rather than about the act.

**The bot cannot see a threat.** `makeAimBot` steers at obstacles and at rings. It does not
avoid a predator, it does not notice the swarm shrinking, and a carrier eaten costs it no
restart at all — so five hunters were added to an act and its restart count moved from 19.3
to 19.7. The rate fell only because the same absolute number of restarts is now spread over
28 % more sections.

So the sweep gained a column, and the column is the difficulty that was added: **157
carriers taken a run**, against act I's 121 and act VI's zero. Per minute of run that is 4.0
against the trench floor's 6.5 — the back half of the campaign has a real threat again, and
still a less relentless one than the act that teaches the game.

Two other things the table does say plainly:

* **`run ÷ authored` went 1.05 → 1.53.** A completed run is now half again as long as the
  course it flies, which is the replay cost of longer stations stated in a unit that does
  not move when the act does. This is the number to watch on a phone.
* **The 1800-second cap had to go.** At 25.7 authored minutes the flat budget was below the
  act's own length plus one restart, so the first measurement of the second pass came back
  0/7 finished and a *lower* restart rate — an instrument reporting a longer act as an
  easier one. The cap scales with the act now, floored at the old value so nothing already
  measured moves.

### What the second pass deliberately did not do

**The plasma got the smallest share of the new length** — two sections, both new demands
rather than repetitions. It is the one station with no rest in its middle, §7 named "is the
plasma at three minutes an endurance test?" as an open question, and that question has still
not been answered on a phone. Doubling a station while its one known risk is unmeasured is
how you find out too late.

**`RESTARTS_PER_ACT` was not touched in this pass**, and was flagged as the player's
decision rather than the author's. It has been taken since — see §10, where it becomes a
rate off the act's own authored length. Act V carries four attempts; no unrebuilt act moves
by one.

**Gap widths still do not tighten**, `pace` still does not rise anywhere, and the failure
system is untouched. Same as §13.

## 10. Then it was played again, and the fall turned out to be free

The second pass went back to the phone and came back with something neither pass had
looked for:

> *"It goes downward now. I can descend with the swarm much faster than the background and
> the obstacles scroll up. There is nothing exciting or enjoyable in that — the top of the
> course basically never catches up with me, so I can never die."*

**It is right, it is right by construction, and it had been true of every falling act since
the campaign turned over.** `World.step` advances the camera at the station's forced drift
and then takes the *greater* of that and the swarm's own position:

```ts
this.cameraY += this.act.direction * this.currentWorldSpeed * dt;
const target = c.y - this.height * this.anchorFraction;
if (this.u(target) > this.u(this.cameraY)) this.cameraY = target;
```

There is no upper bound on the follow, and the only failure of position in the game is
`sweptAway`, which fires when the swarm falls *behind*. So a hand that pushes forward drags
the world along with it, and `behindFraction` pins at exactly the anchor — 0.620 measured on
every act and every bot style — against a strand line of 0.94. **The one way to lose ground
in this game is unreachable by anybody who pushes.**

On a climb that costs effort, because the swarm is going against the medium. On a fall it is
free, because the medium is already taking it that way. Measured on `tools/rush.sweep.ts`,
three seeds, 300 s, before any fix:

| act | careful ground | rush ground | rush speed ÷ world | rush carriers lost | rush restarts |
| --- | ---: | ---: | ---: | ---: | ---: |
| I · water | 21 560 | 20 948 | 0.98 | 50 | 6.3 |
| V · reentry | 13 072 | **25 975** | **2.29** | **0** | **0** |
| VII · home | 15 786 | 15 783 | 4.99 | 36 | 0 |

Act I is immune: rushing a climb buys nothing. Act V doubles its ground at 2.29 times the
world's own travel and pays *nothing at all* for it. That is the report, as arithmetic.

### The instrument that could not see it, and why

Every bot in the repo — and every probe in `e2e/` — gates its forward stroke on
`behindFraction > 0.5..0.62`, which is to say **it stops pushing at the camera's anchor.**
And the follow pins the swarm at exactly that anchor, so the gate was unconditionally true
and had never once fired. A gate that is always open is indistinguishable from no gate at
all. `makeAimBot({ rush: true })` is the hand the report describes and it did not exist.

### The fix is the medium's, and three reasons it is not the camera's

Bounding the follow is the obvious answer and it is wrong three times over:

* **It makes the reported symptom worse.** Every parallax and backdrop plane in the game
  reads `viewCameraY`. Pinning the camera slows the background the player has just said is
  too slow, permanently and totally, while the swarm runs to the leading edge.
* **It breaks the input.** `FlowField` is a camera-anchored grid about one screen tall. A
  swarm more than ~96 px past the leading edge deposits strokes into a grid it is no longer
  inside and samples a clamped edge cell — it stops being steerable, silently.
* **This repo has already run that experiment and lost it.** `World.advanceView`'s comment
  records it: a cap on the follow moved the careful bot's score from 1473 to 1209 while the
  flailing bot's *rose* from 700 to 984. *The camera's motion is a picture; the camera's
  position is a rule.*

Also measured and rejected on the way: bounding the camera by a leash costs act I 37 % of
its ground, which moves the bit-identical canary; and a "surge" that speeds the world up to
collect the ground the follow gave away is a `pace` rise, which §11 forbids, and it is
invisible — the player would have no idea why the world got faster.

### `Medium.drag`: the air has a speed, and outrunning it burns

A body that outruns the air it is falling through is not slowed by that air. It is
**heated** by it. So past `Tuning.terminalFactor` (1.6) times the station's own drift, the
swarm begins to ablate — **from the front, because the front is what is meeting the air** —
at `Medium.drag` carriers a second per whole terminal of over-speed, squared.

Squared because convective heating goes as the cube of speed, and because it buys the shape
this needs: **a soft shoulder and a hard wall.** A careful hand drifts a little over the
terminal, because a centroid is a body and not a point, and pays almost nothing for it. A
hand that decides to outrun the act pays quadratically.

`drag` is **zero in five of the seven media**, so this is one branch in the whole rest of the
campaign:

* `space` — nothing there to outrun, which is why act V's deorbit is the free station and
  should be;
* `water` — act I is defended digit for digit and act VII must not grow a threat in its last
  minutes;
* `air`, `thinAir` — acts II and III are climbs, and nothing has measured them;
* `cloud` — act VI reads it too, and §9 has just finished saying that changing an act nobody
  has measured is the mistake. **This is the next thing to try.**

That leaves `plasma`: the four stations in the middle of act V where the air arrives.

It ends through the door that already exists. Sustained over-speed empties the swarm into the
40 % floor and the station begins again — **no new failure reason, no new ending copy, no new
Game Over screen.** The failure system is on the do-not-reopen list and this change did not
need it to move.

### The measurement that says it is a demand and not a rail

`careful` never goes fast enough to be charged and `rush` never stops; neither is the
interesting player. So there is a third hand: `brake` pushes exactly as hard as `rush` until
`World.ablating` says the medium has started taking the swarm, and then strokes **against**
the course until it stops. That is act V's stated verb — *brake, and accept the medium* —
written as eleven lines of policy.

| hand | ground | speed ÷ world | over terminal | carriers burnt | restarts |
| --- | ---: | ---: | ---: | ---: | ---: |
| careful | 11 985 | 1.31 | 18 % | 29 | 0.3 |
| rush | 17 086 | 1.77 | 59 % | **671** | **33.3** |
| **brake** | **13 710** | **1.43** | 26 % | **9** | **0.3** |

The braking hand makes 14 % more ground than the careful one, goes 10 % faster, and burns
*fewer* carriers than either — because it is the only one of the three answering the signal.
Over a shorter window inside the plasma the gap is starker still: 2.3 times the careful
hand's ground for four carriers, where not looking buys 2.8 times for sixty-seven.

**Speed is available. It is available to anyone who looks.**

### Act VI already had a price on its fall, and it is called the course

`Medium.drag` is a per-medium number, so the obvious next move was to turn it on for `cloud`
and `stream` and give acts VI and VII the same rule. It was turned on, at 2 and 2.5, and
**measured, and turned back off** — which is the more useful result:

| act VI | ground | speed ÷ world | carriers burnt | restarts |
| --- | ---: | ---: | ---: | ---: |
| careful | 15 182 | 1.08 | 0 | 1.0 |
| rush, no terminal | 11 932 | **0.83** | 0 | 9.0 |
| rush, terminal at 2 | 484 | 0.05 | 1 296 | **92** |

**Rushing act VI is already slower than flying it carefully.** Twenty-four sections of dense
weather at 1.7 obstacles a minute do not need a rule about speed; a hand that pushes simply
flies into them, and takes nine station restarts for it where a careful one takes one.
Turning the terminal on charged the act 1 296 carriers and 92 restarts for a fault it does
not have.

`stream` stays zero for that reason and one of its own: its only stations are act VI's last
two, which the measurement above covers, and act VII's salt line — one station from the three
that cannot be lost at all. `water` stays zero because act I is defended digit for digit and
because rushing a climb buys nothing anyway (0.98 of a careful hand's ground, measured).

So the fall has a price in exactly one place, and that place is the four stations of act V
where the air arrives. **The rule is the medium's; whether a medium wants it is a
measurement.**

### The restart budget stopped being a constant

`RESTARTS_PER_ACT` was 2, and it was the smallest number that answered both ends of
`sim/Failure.ts`'s argument — a station may be got wrong and learned, an act may not be
ground out. It was chosen when every act was about ten authored minutes and a station about
1.7.

Act V is 26.5 minutes now, with stations of 4.2 to 5.1. **The budget per minute of content
had quietly halved, across two passes, without anybody deciding that it should.** A count
that holds still while the thing it counts doubles is not a decision; it is an oversight
with a constant in front of it.

So it is a rate: one more restart per seven authored minutes past twelve, floored at the old
two and capped at four. Twelve is the top of the band the unrebuilt acts sit in, so **not one
of them moves by a single attempt** until it is actually rebuilt; four because a fifth would
make a long act something to be ground out. It is computed once, in `makeAct`, off the act's
own authored length, because three call sites each working it out for themselves is a number
that disagrees with itself inside a month.

### ...and the warning that had never been drawn

The game has exactly one "you are losing" cue — the gradient that rises from the trailing
edge as the swarm sinks toward the strand line — and it read a raw screen fraction rather
than `behindFraction`, and painted at the bottom of the frame. On a climb those agree. On a
fall, behind is the **top**, and the camera holds the swarm at 0.38 of the frame, so the
threshold was unreachable by construction. Measured with a passive hand: act I paints it on
19.9 % of frames and act V on **0.00 %**.

So all three falling acts have been shipping with no warning of the one failure they had —
which is the other half of "I can never die". It is fixed, and the new heat is its mirror:
the same gradient, the same warm, drawn at the edge the swarm is running *toward*. Two edges,
two dangers, one visual language. **The frame closes in from whichever side you are getting
wrong.**

## 11. It was done six more times, and this is the circuit

| act | before | after | obstacles | ob/min | moving | hunters | restarts |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| I · The Deep | 42 · 10.0 min | *frozen* | 35 | 3.5 | 0 | 3 | 2 |
| II · Flight | 36 · 7.7 | **91 · 21.7** | 78 | 3.6 | 17 | 7 | 3 |
| III · The Thinning | 20 · 10.2 | **65 · 22.2** | 47 | 2.1 | 11 | 0 | 3 |
| IV · Orbit | 18 · 11.4 | **56 · 20.6** | 43 | 2.1 | 9 | 0 | 3 |
| V · The Fallback | 24 · 10.9 | **73 · 26.5** | 60 | 2.3 | 17 | 5 | 3 |
| VI · The Rain | 24 · 9.7 | **61 · 21.2** | 48 | 2.3 | 14 | 0 | 3 |
| VII · The Homecoming | 18 · 12.1 | **44 · 21.9** | 28 | 1.3 | 8 | 0 | 3 |
| **circuit** | **182 · 72 min** | **432 · 144.1 min** | **339** | 2.4 | **76** | **15** | |

**Act I is frozen and stays frozen.** It is the metronome the other six are heard against,
its numbers are defended digit for digit, and it is the act a player meets first with
nothing learned. Everything else is between 20.6 and 26.5 authored minutes.

144 authored minutes is **about 108 as played** — `World.pressure` adds up to 55 % to the
forced drift across a station, so a competent hand runs roughly three quarters of the
arithmetic. That is the middle of the two-to-two-and-a-half hours §2 asked for.

Five of the six were authored in parallel, one agent per act, each in its own file. Two
things about that are worth writing down rather than leaving as folklore:

* **None of them could run anything.** A permission classifier blocked every `npx`, `npm`
  and `node` call after their first few, so every number they reported was hand-computed
  and no corridor sweep, typecheck or test was run by the author of any act. All of it was
  verified afterwards, from here, and the safety net held: `tests/levels.test.ts` flood-fills
  every section of every act and each act's own file sweeps its corridor and its ring chain.
  Every one passed. **The guarantee that nothing in this campaign can be impossible is a
  property of the tests, not of who wrote the level.**
* **One rule was broken and it was a number, not a design.** Act IV asserted *exactly one*
  orbital gate per station, and the rebuild put twelve in an act of fifty-six sections. What
  the assertion was protecting — the bow escalates station by station and the Overview has
  none — is intact and measured: 0.10, 0.18, 0.22, 0.34, 0.42, and nothing in the Overview. The
  count was an artefact of an eighteen-section act and has been replaced by the claim it was
  standing in for.

`tests/stations.test.ts` is new and is where the measured rules live now. They were act V's
and lived in `tests/reentry.test.ts`, where they guarded one act; six acts are built to them
now, so a rule that only holds act V is a rule five acts can break silently. All six pass.

### ...and the fall's price had to be re-measured, because the rebuild moved it

§10 turned `Medium.drag` on for `cloud` and `stream`, measured act VI, and turned it back
off: rushing act VI was *already* slower than flying it carefully — 0.83 of the world's own
travel against 1.08, nine station restarts against one — because twenty-four sections of
dense weather punish a hurry all by themselves.

**That measurement was true and went stale the same day.** Rebuilt to 61 sections with two
rests a station, act VI stopped punishing it: the same hand measured 1.33 and one restart.
The rests are what made the fall free again — which is the length plan handing this rule its
own reason to exist. So `cloud` is 0.6 and `stream` 0.5, both far under the plasma's 3
because nothing is on fire at twelve kilometres, and the numbers land here:

| | careful | rush, blind | **rush, braking** |
| --- | ---: | ---: | ---: |
| VI · ground | 11 880 | 2 222 | **19 551** |
| VI · carriers burnt | 1 | 524 | **0** |
| VII · ground | 11 377 | 33 199 | **32 267** |
| VII · carriers burnt | 1 | 33 | **0** |

A hand that pushes hard and watches the frame makes 1.65 times the careful hand's ground in
act VI for nothing at all. A hand that pushes without looking makes a fifth of it.

## 12. What this cost, and what is left

Act V went from 24 sections to 73 and the circuit from 182 to 432. The engine work is done:
motion turned out to be one mechanism rather than fourteen shapes, the third predator
silhouette is built, and the fall has a price. Every remaining demand is one line on any of
the seventy shapes the game already draws, in any act.

**What is not done, and it is the only thing that matters now: nobody has played it.** Six
acts were rebuilt in one afternoon and verified by tests, and tests answer *can this be
flown* and *does it obey the rules*. They do not answer whether act III still feels like
patience, whether act II is still the act this repo is proudest of, or whether twenty-two
minutes is the right size for a station-and-a-half of attention. The things to watch, in the
order they will be met:

* **Act II at 91 sections.** It was the densest act in the campaign and it is now the
  longest but one. Its own file argued that padding it would be wrong; it gained content
  rather than distance, and whether that reads as generous or as relentless is a matter for
  a thumb.
* **Act III's silences.** The act's verb is *wait, and choose a layer*, and length is the
  easiest thing in the world to spend on filling silence. It measured 2.1 obstacles a minute,
  the second-thinnest in the campaign, which is the number saying the silences survived.
* **A five-minute station lost.** Every act carries three attempts now instead of two, but a
  station is four to five minutes rather than 1.7, and the two multiply.
* **The heat, on a phone.** The bots say a hand that watches the frame beats one that does
  not. A bot is not a player, and the whole of whether the terminal is a demand or a tax is
  whether the leading edge is read as a warning in time.

## 13. Not reopened here

The failure system (the hunter, the 40 % floor, the Game Over screen), the visual language,
`blue-rise`, and the ban on post-processing. `pace` does not rise anywhere. Gap widths do
not tighten as a difficulty lever.
