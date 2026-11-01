---
name: silhouette-primitives-are-spent
description: Each enemy archetype owns one silhouette primitive and six are already taken; the ringed iris belongs to the boss and warm pixels mean enemy
metadata:
  type: project
---

The level 1 enemies each own **one silhouette primitive, and no two share it**: pod (basic), fork
(light), anvil (shooter), needle (rush), bunker (tank), wing (carrier). A seventh archetype has to
take a primitive nobody is using — not a variation on one of these.

Two rules came with it and hold campaign-wide:

- **The ringed iris belongs to the boss and to nothing else.** An ordinary enemy gets a bare warm
  muzzle of 1 to 7 px with no ring around it.
- **Warm pixels mean "this is where an enemy hurts you".** Their placement and count say *how* it
  shoots; the carrier has none, which is the only way to draw an enemy that never fires. The player
  ship's accent was moved from W3 to C1 for the same reason — cyan is the player's and warm is not.

**Why:** the first pass gave all six a rounded violet mass, a ringed orange eye and yellow legs, so
basic and shooter were one enemy in a crowd and light and rush were another. That is invisible in
the source and invisible sprite-by-sprite; it only shows on a contact sheet.

**How to apply:** before drawing any new enemy, name its primitive and check it against that list.
Run `python docs/design/mockups/render.py enemy 10 flat` and Read the PNG — that is the silhouette
test of `05-legibility-rules.md`, and `flat` mode exists for it.

Related: [[palette-invariants]], [[alien-ramp-has-one-chromatic-step]], [[art-production-needs-a-shell]]
