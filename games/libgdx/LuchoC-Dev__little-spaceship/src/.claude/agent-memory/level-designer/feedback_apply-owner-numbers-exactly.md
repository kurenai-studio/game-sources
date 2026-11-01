---
name: apply-owner-numbers-exactly
description: A balance number handed down from a play session is a decision to apply verbatim, with disagreement recorded in the status fragment rather than absorbed into the value.
metadata:
  type: feedback
---

When a play session produces numbers, ship them exactly as given. If the arithmetic says one of them
breaks something, apply it anyway and report it loudly in the status fragment as the next session's
first watch-item — never split the difference, and never quietly pick a safer value.

**Why:** balance in this project is settled by playing, not by derivation — decided on 22/08, 25/08
and again on 01/09/2026. A value that is silently "improved" by a designer breaks the loop: the next
session then plays something the owner never chose and cannot tell whether their own decision was
wrong or whether it was never tried. Stated explicitly when phase 11e handed down the health cuts
(#210): *"the numbers are the owner's decision, not a proposal for you to improve."*

**How to apply:** the fragment is where disagreement goes, with the arithmetic and the source line
that produces it, framed as "check this next session" rather than "this is wrong". The same applies to
a number that is merely *arguable* — `enemy-tank` at 200 and the bomb at 7% of a carrier both went into
#210's fragment as observations, not edits.

A corollary the same issue made explicit: **make the JSON say what is true.** `enemy-light` was to lose
its durability, and because `DamageSystem` treats any value at or below `weaponProjectileDamage` as no
component, the change was to *remove* the component rather than write `10`. A value that reads as a
decision and behaves as an absence is worse than no value.

Related: [[carrier-spawner-survival-window]], [[enemy-durability-arithmetic]].
