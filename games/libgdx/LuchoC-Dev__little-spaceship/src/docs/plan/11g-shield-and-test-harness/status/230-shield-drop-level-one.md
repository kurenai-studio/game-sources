# 11g / #230 — A `shield` drop in level 1

**Branch:** `feat/shield-drop-level-one` · **Owner:** `level-designer` · **Closes:** [#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230)

## What changed

One line of `assets/data/waves.json`, and the regenerated `docs/levels/level-01.md`:

```jsonc
// wave l1-combined-formations
{ "at": 4.0, "spawn": "enemy-basic", "formation": "line-3", "atX": 0.30, "drop": "shield", "dropSlot": 1 }
```

`l1-combined-formations` is placement #4, starting at 33.0 s, so the shield falls at **37.0 s**, from
the centre enemy of a three-wide `line-3` of `enemy-basic` entering left of centre — the formation
spans x 36.9 .. 87.9, so slot 1 sits at about x 62, against a player who starts at x 104.

`assets/data/level-01.json` is untouched: the twelve placements, their offsets, the boss block and
the 134.5 s length are exactly what the project owner signed off on 01/09/2026. Nothing else in
`assets/data/` moved.

## Why there, against the curve

The pacing table in `docs/levels/level-01.md` gave this drop cadence before the change:
11.0, 48.0, 86.0, 92.5, 97.5, 113.5. **The whole first half held one reward**, and there was a
37-second silence between the opening `weapon-upgrade` at 11.0 s and the next one at 48.0 s — the
longest reward drought in the level, covering exactly the beats where it stops being an
introduction.

Placement #4 `l1-combined-formations` is the level's **first density spike** — 1.77/s, higher than
anything before it and not exceeded again until 88.0 s — and the first beat that combines two
archetypes on two shapes (`enemy-basic` on `slow-descent` under `enemy-light` on `swoop`). It
carried no drop at all. It is also the last moderate point before the run of beats a shield is
actually for: `l1-tanks-and-priority` (46.0 s), `l1-super-fast` (58.0 s) and the carrier (67.0 s).

That agrees with the phase's stated opinion — *a shield is worth having before it is needed* — and I
agree with it after checking the alternatives, not instead of checking them:

- **Wave 3 `l1-light-and-fast` (22.0 s) is too early.** `core/domain/component/Shield.java` is a
  marker with no durability: the first contact of any kind consumes it. At 22-33 s the pressure is
  one archetype on one shape, so the shield would be spent on a stray `enemy-light` well before the
  player meets anything the icon is meant to teach them about.
- **Wave 5 `l1-tanks-and-priority` (46.0 s) is the placement to avoid.** It already carries the
  second `weapon-upgrade` at 48.0 s. A shield there is a prize beside a prize, two seconds apart,
  and it leaves the 11→48 drought exactly as it was.
- **Wave 6 `l1-super-fast` is unusable as a carrier.** `core/domain/system/LifetimeSystem.java`
  strips `Drop` from an enemy that leaves the playfield, and `enemy-rush` is fast and fragile, so
  the drop would be lost outright on a miss. `enemy-basic` on `slow-descent` (vy -18) stays on
  screen for roughly 16 s, which is why all three existing `weapon-upgrade`s ride that archetype.
  This one does too.

`dropSlot 1` is the centre slot, the same convention as the two existing `line-3` drops. The pickup
is attached to that slot alone — `SpawnSystem` attaches it only when `i == event.dropSlot()` — so
the two outer enemies carry nothing.

## What it costs

**It softens beats 5 to 8 for a player who collects it.** A shield in hand at 37.0 s is one free hit
carried into the tanks, into `l1-super-fast` and possibly as far as the carrier at 67.0 s. That
stretch was tuned across two play sessions without it. The cost is bounded — one hit, one time, and
`PickupSystem` grants nothing if a shield is already up, so it cannot stack — but it is real, and it
is the change this phase makes.

**It also takes level 1 from six drops to seven in 134.5 s.** The second-order effect worth watching
while playing is not the shield itself but whether reaching the 48.0 s `weapon-upgrade` now reads as
a run of gifts rather than two separated beats.

## For `docs/planning/08-decisions-and-open-items.md`

This changes level 1's balance and the acceptance criteria ask for it to be recorded. The
coordinator writes that entry, not me. What belongs in it:

> **Level 1 carries a `shield` drop at 37.0 s** (`l1-combined-formations`, `enemy-basic` in
> `line-3`, slot 1), added 01/09/2026 in phase 11g so that the `icon-shield` HUD element wired by
> #43 is reachable in play. It is the level's only drop between 11.0 s and 48.0 s, and it is
> deliberately placed **before** the beats it defends against rather than beside them. Open until
> the project owner plays it: whether one free hit carried into beats 5-8 softens a stretch that was
> tuned without it.

## For the project owner — how to verify it

1. `./gradlew :desktop:run`, start level 1.
2. Play normally to about **37 seconds**. That is inside the fourth beat, the first one where slow
   `enemy-basic` lines and swooping `enemy-light` diagonals share the screen.
3. Watch for a **three-wide horizontal line of `enemy-basic`** entering **left of centre**, about a
   third of the way across the playfield, descending slowly. It is the fourth spawn of that beat.
4. **Destroy the middle one of the three.** The outer two carry nothing; only the centre slot does.
5. A `pickup-shield` falls from it. Collect it.
6. **`icon-shield` should light in the HUD's STATE block.** It stays lit until the first hit you
   take, which consumes the shield and clears the icon.
7. If you die before 37 s, or miss the centre enemy, there is no second chance — it is the only
   `shield` in level 1.

## Verified

- `node tools/build-level-docs.js` — printed `updated docs/levels/level-01.md`,
  `unchanged docs/levels/waves.md`. The drop appears in "Drops and rewards" at 37.0 s, which also
  confirms `shield` is one of the six kinds the generator accepts; the spelling comes from
  `core/domain/system/PickupSystem.java:42`, `KIND_SHIELD = "shield"`.
- **The Checks section carries only the two expected findings** — the negative offsets on placements
  #9 and #10. No new finding, in particular none about a drop kind or a `dropSlot` out of range. The
  boss-over-its-wave finding is not present in this level's document at all: the gap between the
  last wave and the boss is 0.0 s.
- `./gradlew build` — exit 0.
- `./gradlew :desktop:run` — launched once, ran for 40 s with no exception in the log (LWJGL
  loaded, only the usual JDK native-access warnings), then killed. **I did not look at the window
  and took no screenshot**, and I did not play it.

## Not checked

- **Whether it plays well.** Per "Running the game is not playing it" in
  `docs/plan/how-to-run-a-phase.md`, whether the shield lands at the right moment, and whether it
  flattens beats 5-8, is the project owner's verdict from the steps above.
- That `pickup-shield` renders as a falling sprite. That is `game`'s surface and was 11f's work.
