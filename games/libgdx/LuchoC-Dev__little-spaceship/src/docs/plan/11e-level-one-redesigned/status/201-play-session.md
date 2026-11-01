# #201 — Play the candidate: the length, and the four watch-items

**Task 5 of phase 11e**, and the one no agent could do. Played by the project owner on 01/09/2026 on
the desktop target, `./gradlew :desktop:run`, against the candidate at commit `7a94d78` on
`phase/11e-level-one-redesigned`.

This file records what the session found. What it *changed* is
[#210](https://github.com/LuchoC-Dev/little-spaceship/issues/210); what it *decided* is in
`docs/planning/08-decisions-and-open-items.md` under "Level 1 played, 01/09/2026".

## The six questions

The five from the plan's running order, plus one the candidate itself raised.

**1. Does `enemy-basic` read as firing less often than `enemy-shooter`, or does it just die too fast
to tell?**

**"Se nota poco"** — hinted at, not clear. Recorded as a partial answer and not resolved further. The
plan says in as many words that an unclear answer is an acceptable one and is recorded as that. The
`Health` of 30 that #199 gave the basic did move this from invisible to faint; it did not settle it.

**2. Does the boss at `patternCooldown 0.7` feel like a boss — and is the tell still honest after the
aim change?**

**Yes, and this is the session's strongest result.** The owner's words: the boss's difficulty is
*ideal*, neither too hard nor too easy. One session earlier the same fight was diagnosed as *"a
positioning problem solved once, not a dodge"*, beatable by parking at screen centre. The redesign in
[#200](https://github.com/LuchoC-Dev/little-spaceship/issues/200) — aim locked at tell-start, five rays
per part — is confirmed by play.

The one change asked for is small and explicitly framed as small: lower the projectile speed *"un
mínimo"*. `spreadProjectileSpeed` 95 -> 85, `sweepProjectileSpeed` 140 -> 125. Nothing else about the
fight moves.

**3. Does `enemy-rush`'s single likely shot per pass read as "shoots little" rather than "does not
shoot"?**

**Yes.** Answered directly and without qualification. No change.

**4. Is `enemy-light`'s 130 u/s projectile dodgeable?**

**Yes.** Answered directly. No change.

**5. Is the length right?**

**Yes** — the first level is right as played. The 27/08 target of around three minutes including the
boss is met. Per the rule decided on 22/08 and again on 25/08, the number is fixed by playing, and
this is that.

**6. Do spread and sweep still read as two distinct patterns, now that both fan around an aimed
direction?**

**Not answered.** The session did not report on it and it was not asked about directly. **Still open**,
and it matters: the decided rule from 21/08 is one phase with *two alternating* patterns, and after
#200 the two differ only in which parts fire and at what speed. Carry it into the next session.

## What the session found that no question asked about

Both of these are the reason a play session is not a questionnaire.

**Enemies at the very start.** Beat 1 is the audiovisual introduction, and the candidate gave it
`l1-intro-flyover` — five `enemy-light` on `dive` at 0.0 s. The owner: enemies appear at the start,
*"algo que no debería pasar"*.

**Enemies still arriving as the boss enters.** Beat 14's `l1-boss-approach` is a 7 s escort starting
exactly at `boss.entersAt`, built deliberately so that "fourteen waves, one per beat" could be
satisfied. The owner read it as a bug — *"creo que este no es la última ola"* — which is the honest
verdict on a wave that exists to satisfy a count.

**Both waves are removed** in #210, and the acceptance criterion they were built to satisfy is
rewritten rather than worked around. `docs/plan/11c-movement-shapes/shape-catalogue.md`'s original beat
map had already said "none; no enemies" for beat 1 and left beat 14 to `BossSystem`; the candidate
overrode that reading to make a number come out even, and play found it in one run.

**Too much health, and only in the first stretch.** The basic took three shots and the level was hard
until the first weapon upgrade. **After the upgrade the difficulty was high but acceptable for the
genre**, and that half is deliberately untouched. Asked how far to go, the project owner chose all of
it down: basic 30 -> 20, light -> no `health` component, shooter 40 -> 30, tank 300 -> 200, carrier
1000 -> 700.

## What this says about the phase's own method

`docs/STATUS.md` calls playing *"the only source this project trusts for balance"*, and the phase was
structured around that. The session earned it twice over:

- **It reversed a change made one day earlier on the same evidence.** #199 raised enemy health because
  the repository's own arithmetic said a carrier died in 1.2 s against a 32 s stretch. Play said the
  first ninety seconds were too hard. Both were right about their own question, and only one of them
  was about the game.
- **The two defects it found were invisible to every check that exists.** `tools/build-level-docs.js`
  reported the Checks section clean for both `l1-intro-flyover` and `l1-boss-approach`; `pre-pr-check`
  was green; `reviewer` audited beat 14 specifically, called it "a sound design call, correctly
  argued", and I agreed with that reading when I merged it. It took one run to see it was wrong.

## For the next session

- **Question 6 is unanswered** and is the one open item that touches a decided rule.
- **`enemy-carrier` at 700 is the number to watch.** At 80 it died before its `spawner` produced a
  single child and its whole designed mechanism never happened, which is the defect #199 fixed. 700
  moves back toward that floor.
- **`bombDamage` 50 against a carrier at 700** removes 7%, against 62% at the old 80. Still open,
  recorded in `docs/planning/10-mvp-initial-values.md`, and untouched because the bomb also lands on
  the boss's parts.
- **Question 1 is only answerable early.** The weapon upgrades mean a basic, light and shooter all die
  to one pull at shot level 4 whatever their health.
