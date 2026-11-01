# #192 — The boss section stated a falsehood and printed a column for a place two rays never reach

**Branch:** `fix/boss-projectile-geometry` · **Closes:** [#192](https://github.com/LuchoC-Dev/little-spaceship/issues/192) · **Written:** 31/08/2026

A defect found by the coordinator's audit of the phase, after the `reviewer` pass died on the
account's monthly spend limit. The precedent for the coordinator auditing in that situation is
`.claude/agent-memory/reviewer/` and phase 03's own review on 20/08/2026.

## What was wrong

`docs/levels/level-01.md` said, of the boss's six projectile rays:

> Every ratio is shallower than 45 degrees, so every projectile exits through a side edge

**Two of the six are steeper than 45° and leave through the floor.** The spread's `vy` ratio is `-0.90`
against `vx` ratios of `0.25` and `0.45` (`core/domain/system/BossSystem.java:140-143`), so those rays
are more vertical than horizontal. Against `combatY 175.0`:

| pattern | ratio | to a side | to the floor | leaves through |
|---|---|---|---|---|
| spread | 0.25 | 4.38 s | 2.05 s | **the floor** |
| spread | 0.45 | 2.43 s | 2.05 s | **the floor** |
| spread | 0.70 | 1.56 s | 2.05 s | a side |
| sweep | 0.55 | 1.35 s | 1.92 s | a side |
| sweep | 0.75 | 0.99 s | 1.92 s | a side |
| sweep | 0.95 | 0.78 s | 1.92 s | a side |

The printed column, `y at the side edge`, therefore gave `-199.4` and `-33.0` for the first two — a y
below the playfield floor, for a place those projectiles never reach.

**And it answered the wrong question.** The section states its own purpose — whether a ray reaches the
player's band — and the figure that answers it is where a ray is when it *crosses* that band.

## Completed

The column is replaced by two, both derived rather than assumed: **which edge each ray leaves through
and when**, and **how far from the boss it is when it crosses `playerStartY`**, marked when the ray has
left the playfield before getting there.

```
| pattern | vx ratio | vx | vy | leaves through | x from the boss at y 30.0 |
| spread | 0.25 | 23.8 | -85.5 | the floor, 2.0 s | 40.3 |
| spread | 0.45 | 42.8 | -85.5 | the floor, 2.0 s | 72.5 |
| spread | 0.70 | 66.5 | -85.5 | a side, 1.6 s | **off the playfield already** |
| sweep | 0.55 | 77.0 | -91.0 | a side, 1.4 s | **off the playfield already** |
| sweep | 0.75 | 105.0 | -91.0 | a side, 1.0 s | **off the playfield already** |
| sweep | 0.95 | 133.0 | -91.0 | a side, 0.8 s | **off the playfield already** |
```

**That table reproduces, from geometry alone, the diagnosis `docs/STATUS.md` already carries** in the
post-MVP backlog — *"the spread always points outward and the sweep inward, so a player parked in the
centre is never threatened"*. Four of the six rays are off the playfield before they reach the player's
height; the two that are not sit 40 and 72 units either side of the boss's centre. The old column
obscured exactly that.

Section 11 of [`../document-contract.md`](../document-contract.md) carried the same false sentence and
is corrected in place, dated, with the arithmetic.

## Decided

- **The document prints where the rays are and stops.** It does not say the fight is too easy. That is
  a judgement, `docs/planning/` holds the design opinion, and the contract refuses generated judgements
  because nobody signs them and nobody can argue with them. The one general sentence it does carry —
  that a boss all of whose rays read "off the playfield already" is unlosable — is arithmetic about the
  format, not about this boss.
- **Nothing about the boss changed.** Its aim is a post-MVP backlog item and `BossSystem` is
  [#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88), phase 12. This makes the document
  tell the truth about the boss that exists.

## Open

Nothing from this defect. The wider point it illustrates is already recorded: a constant or a
derivation quoted from `core/` cannot be kept honest by regenerating, and this one survived a contract,
a generator, a CI check and a read-back because every one of them read the same sentence rather than
the geometry.
