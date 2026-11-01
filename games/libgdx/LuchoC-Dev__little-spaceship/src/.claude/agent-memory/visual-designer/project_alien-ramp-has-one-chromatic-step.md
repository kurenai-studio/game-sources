---
name: alien-ramp-has-one-chromatic-step
description: Enemies may only use gameplay-class colours, so the alien ramp is V4 then cold metal — not V2/V3/V4, which the palette doc wrongly said
metadata:
  type: project
---

An enemy sprite may contain **only gameplay-class colours plus N0**. `mockups/src/04-audit.js`
enforces it literally, per pixel. So the alien ramp is `N0 -> V4 -> N5 -> N6`: violet mass with
*cold metal* highlights and black joints. V1, V2 and V3 are scenery only.

**Why:** the split is what stops a background swallowing a bullet, and it has no exception for
"it's only shading". `01-palette.md` shipped telling the artist to shade `V2 -> V3 -> V4`, which
fails the validator on the first enemy drawn — found on 21/08/2026 by reading the audit before
drawing, and corrected in the document.

**How to apply:** two consequences that keep biting because they look like colour choices and are
not.

- **There is no dark gameplay colour.** V4 at `L*` 48.1 is the floor. So "thin, dark wing" and
  "interior shadow" cannot be a dark tone — they are made **outline-dominant** instead, a 4 px wing
  drawn `N0 / V4 / V4 / N0`. Anyone reaching for V2 to darken a sprite is about to break the split.
- **A second gameplay violet would go between V4 (48.1) and N5 (64.0)**, around `L*` 56 — never
  between V3 and V4, which is below the floor and therefore background-class. It was not needed at
  23 px, and on the boss it is only avoidable because the boss's dark regions are the channels the
  player flies through rather than shading.

Related: [[palette-invariants]], [[hud-and-size-constraints]]
