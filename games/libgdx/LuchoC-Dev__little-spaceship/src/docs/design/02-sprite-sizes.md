# Sprite sizes and hitboxes

**This is synchronisation point 1.** Phase 03 writes hitboxes from this table and no sprite is drawn
before it. Everything here is in pixels at the logical resolution of 480x270. There are no
proportions in this document: at this size a proportion is unusable.

## The five rules behind the table

**1. Every dimension is odd.** A sprite is drawn centred on its `Transform`, so an odd width puts
the axis of symmetry on a single pixel column instead of straddling two. Even dimensions produce a
ship that visibly wobbles when it crosses a half-pixel.

**2. The collider is a circle, centred on the same point.** `core.domain.component.Collider` is a
radius and a layer — there is no offset field and no rectangle. So the hitbox is always concentric
with the sprite, and the art has to be drawn around that: the visual mass belongs at the centre.

**3. Collidable mass sits inside the circle.** Anything outside must be thin and read as secondary
— wingtips, antennae, exhaust. A player who shoots a wing and sees nothing happen is looking at a
bug, whether or not the code has one. Two numbers, both measured on **hull pixels only**, since the
outline is thin by definition and is what a wingtip is mostly made of:

- a row may put at most **3** hull pixels past the radius on either side;
- no hull pixel sits more than **3 px** past the radius.

This replaces the original wording, "at least 85% of opaque pixels fall within the radius", which
was corrected on 22/08/2026 when the enemies were drawn against it. That figure is unreachable for
anything elongated and always was: `enemy-rush` is 15 px tall against a 4.0 radius and peaks near
53% however it is drawn, and the player ship reaches 24% by design. The fraction was never the
thing being protected — the absence of thick mass outside the circle was.

`mockups/src/01-sprites.js` measures both numbers and `check.js` reports them, for ids beginning
`enemy-`, `structure-` and `boss-`. The player ship and projectiles are exempt, because rule 4 makes
their colliders deliberately unlike their art and measuring them would report the generosity back
as an error.

**4. Generosity always favours the player.** It is applied by ratio, in one direction only:

| | Hitbox against sprite |
|---|---|
| Enemy fire | **smaller** — it kills you at less than it looks |
| Enemies and structures | **as drawn** — you hit what you aim at |
| Pickups | **larger** — they feel magnetic |
| The player ship | **far smaller** — 6 px across a 15 px ship |

**5. Radii may be fractional.** `Collider.radius` is a float and the comparison is a squared
distance, so 4.5 costs exactly what 4 costs.

## Player

| What | Sprite | Radius | Proposed id | Notes |
|---|---|---|---|---|
| Ship | 15x17 | **3.0** | `ship-basic` | the 6 px hitbox is the fuselage, not the wings |
| Ship explosion | 31x31 | — | `fx-explosion-player` | |
| Attachment satellite | 7x9 | — | `module-*` | one per side, flanking; no collider of its own |
| Active shield shell | 21x23 | — | `fx-shield` | drawn around the ship while a shield is up; 3 px of clearance on every side |

The ship's hitbox is 40% of its width. That is the whole "smaller than the sprite, but not a single
point" rule from `../planning/02-mvp-functional-spec.md` turned into a number: forgiving enough for
an intermediate-density shoot 'em up, large enough that dodging is about position rather than about
finding an invisible pixel. It is never drawn on screen.

The three wing pixels on each side sit outside the circle by design, and every silhouette of the
ship must keep them thin so the hitbox stays believable.

## Projectiles

Player fire is **cyan and elongated**. Enemy fire is **magenta and compact**. Shape carries the
distinction as well as colour, so it survives a colour-blind player and a bright explosion alike.

| What | Sprite | Radius | Proposed id |
|---|---|---|---|
| Player shot, level 1 | 3x9 | 1.5 | `shot-p1` |
| Player shot, level 2 | 3x9, two of them | 1.5 each | `shot-p1` |
| Player shot, level 3 | 5x11 centre plus two 3x9 | 2.0 / 1.5 | `shot-p2`, `shot-p1` |
| Player shot, level 4 | 5x11 centre plus four 3x9 | 2.0 / 1.5 | `shot-p2`, `shot-p1` |
| Enemy bullet, small | 5x5 | 2.0 | `shot-e-small` |
| Enemy bullet, heavy | 7x7 | 3.0 | `shot-e-heavy` |
| Enemy bolt, aimed | 5x11 | 2.0 | `shot-e-bolt` |

The four weapon levels are told apart by **count and shape**, never by colour: 1, 2, 3 and 5
projectiles, with the wider `shot-p2` appearing from level 3. That satisfies the spec's requirement
that the level be recognisable without a numeric indicator, and it keeps working for a player who
cannot separate the hues.

Enemy bullets are never smaller than 5x5. Below that a projectile stops being a shape and becomes a
speck.

## Enemy archetypes

The six from `../planning/02-mvp-functional-spec.md`, in the order the level introduces them.

| Archetype | Sprite | Radius | Coverage | Proposed id |
|---|---|---|---|---|
| Basic | 13x13 | 5.5 | 85% | `enemy-basic` |
| Fast light | 11x13 | 4.5 | 82% | `enemy-light` |
| Evolved basic / shooter | 15x15 | 6.5 | 87% | `enemy-shooter` |
| Super-fast | 9x15 | 4.0 | 89% | `enemy-rush` |
| Tank | 23x23 | 10.5 | 91% | `enemy-tank` |
| Heavy carrier | 39x31 | 15.0 | 97% of its height | `enemy-carrier` |

Coverage is the collider's diameter against the sprite's **smaller** dimension. It is a description
of the table, not a rule — rule 3 above is the rule, and it is the one the checker enforces.

The carrier is the one exception worth explaining. It is 39 px wide and its circle is 30 across, so
its outer 4 px each side are wing and must be drawn as wing: thin, dark, obviously not hull. Its
mass and its damage-taking silhouette are the central 31x31.

Drawn, the wing came out `N0 / N0 / V4 / V4` rather than the `N0 / V4 / V4 / N0` proposed below.
The reason is rule 3, measured: with hull in the second column the outermost violet sits 3.3 px past
a 15.0 radius and the checker rejects it, and with hull in the third and fourth it sits 2.0 px past
and passes. It also looks better — a black leading edge reads as a swept strut, where a violet one
read as a small bar floating beside the ship.

**"Dark" there does not mean a dark colour** — the gameplay set has none, since the darkest gameplay
colour is V4 at `L*` 48.1, the same tone the hull is made of. The wing is dark because it is
**outline-dominant**: at 4 px it is drawn `N0 / V4 / V4 / N0`, half of it outline, against a hull
whose outline is one edge in twenty. That reads as a thin strut at 1x and it is the only way to get
a dark wing without reaching into the background set, which
[`01-palette.md`](01-palette.md) forbids and `mockups/src/04-audit.js` rejects. Checked when the
21/08/2026 decision made the strong encounter **two carriers at once**: the footprint holds, and it
is not being changed.

Sizes are staged deliberately. The basic enemy is 13 px against the player's 15, so the player never
looks outgunned by a single unit; the tank at 23 and the carrier at 39 read as a different class of
problem the moment they enter, before they have done anything.

## Boss

| What | Sprite | Proposed id |
|---|---|---|
| Boss core | 47x87 | `boss-core` |
| Boss pod, ×2 | 25x25 | `boss-pod` |
| Boss arm, ×2 | 31x45 | `boss-arm` |
| Boss explosion, chained | 95x95 plus medium and large | `fx-explosion-boss` |

The three ids above replace the single `boss-l1` this table proposed before the boss was drawn: it is
five sprites, not one image. The 119x87 footprint below is still the assembled silhouette, and the
radii and offsets in this section are unchanged — see
[`06-boss-presentation.md`](06-boss-presentation.md).

At 119 px the boss occupies 57% of the 208 px playfield: dominant, with dodging room left on both
sides.

**A boss that wide cannot be one circle.** A single collider large enough to cover it would swallow
the gaps the player is meant to fly through. It is built from **six entities** on the `ENEMY`
layer, moved together:

Offsets are in pixels from the boss centre, x growing right and y growing up, as in `Transform`.

| Part | Radius | Offset from the boss centre |
|---|---|---|
| Core | 18.0 | 0, 0 |
| Core keel | 13.0 | 0, -27 |
| Pod, left and right | 12.0 | -34, +6 and +34, +6 |
| Arm, left and right | 14.0 | -44, -22 and +44, -22 |

**This table was five rows until phase 07.** `06-boss-presentation.md` measured, while the parts were
being drawn, that the original five colliders left 25 px of the core's keel unhittable — the first
thing a player shooting upward reaches — and proposed `core-keel` plus moving the arms from -18 to
-22. Phase 07 accepted both; `BossSystem` builds them, and its class javadoc carries the reasoning.
Updated here on 26/08/2026, which is five days later than it should have been: this page says the
art is drawn against this map, so the map has to be the one the code holds.

Phase 07 owned the boss's behaviour, phases and look; this fixes only its footprint and how it takes
hits. A later phase needing different parts changes them here first, because the art is drawn
against this map.

## Pickups and structures

| What | Sprite | Radius | Proposed id |
|---|---|---|---|
| Power-up capsule | 11x11 | 6.0 | `pickup-weapon`, `pickup-shield`, `pickup-life`, `pickup-bomb`, `pickup-invuln` |
| Attachment capsule | 13x13 | 7.0 | `pickup-module` |
| Destructible structure | 31x39 | 15.0 | `structure-*` |

**The structure's collider does not cover its sprite, and no drawing fixes that.** A 39 px tall
sprite on a 15.0 radius has its topmost and bottommost rows 4.5 px past the circle whatever shape is
drawn in it, and a tower — which is what a destructible structure in a burning city is — puts its
heaviest mass exactly there. Measured on `structure-tower` as drawn, the base corners sit 7.8 px
outside. Found 22/08/2026 while drawing it, which is why `check.js` measures `enemy-` only.

Two ways out, for whoever owns the collider:

| Option | Cost |
|---|---|
| Two colliders, radius 11.0 at offsets 0, +10 and 0, -10 | one more entity per structure; covers the sprite to within 2 px |
| Drop the sprite to 31x31 | the structure stops reading as a building |

The first is recommended. The boss has the same problem for the same reason and is written up in
[`06-boss-presentation.md`](06-boss-presentation.md).

Pickup radii exceed the sprite on purpose — 12 px of collision on an 11 px capsule. Missing a
power-up you flew through is the kind of unfairness a player remembers, and nothing about the game
depends on it being precise.

The five power-ups share one capsule silhouette and are told apart by the **mark inside it**: five
pixels square, white, the only thing that changes between them.

It is the same *mark* the HUD uses and not the same pixels, which is a correction made on 22/08/2026
while drawing both. `04-hud-layout.md` gives the life slot a ship silhouette, the bomb slot a W4
core inside an N6 ring and the invulnerability icon a burst over F1; none of those survives being
redrawn at 5x5, and forcing them to would cost the HUD its detail rather than gain the capsule any.
What carries over is the shape family — a cross for a life, a filled round thing for a bomb, a
shield for a shield, a burst for invulnerability, escorts for the attachment — and that is enough
for "learn it once", which was the point of the rule.

The marks stay white rather than borrowing each HUD element's accent colour. White on G2 is the
highest contrast available inside a green capsule, and legibility outranks the tidiness of having
the hues agree.

## Explosions

Sized against what they replace, always larger so the destruction covers its cause.

| What | Sprite | Covers |
|---|---|---|
| Small | 21x21 | basic, light, shooter, rush, projectiles |
| Medium | 31x31 | tank, structures, the player |
| Large | 47x47 | carrier, boss parts |
| Boss | 95x95 | the final chain |

## Frame budget

Not a specification — a budget, so the atlas can be planned and so a sprite is not drawn with
sixteen frames when the game shows four. Art production may adjust it with a reason.

It was adjusted on 22/08/2026, downwards. The ship's idle and thrust were two frames each; they are
one hull frame and a separate two-frame exhaust, because what actually moves when a ship idles is
its flame, and 15x17 of hull redrawn to animate a 5x7 flame is four times the atlas for the same
animation. The tilt is drawn for one side only and mirrored, which is the same decision the boss
already took.

| Animation | Frames |
|---|---|
| Ship idle | 1, plus the exhaust below |
| Ship tilt, each side | 1 held, 1 transition, drawn once and mirrored |
| Ship exhaust | 2, looping, drawn as its own 5x7 sprite under the hull |
| Ship hit | 1, a full N7 silhouette |
| Enemy idle | 2 |
| Explosion, small | 5 |
| Explosion, medium | 6 |
| Explosion, large | 8 |
| Pickup float | 4 |

## What the code lane needs from this page

Only two columns: **sprite** and **radius**. Everything else is for whoever draws. The sprite ids
are a proposal for synchronisation point 2 in phase 04, not a decision this document gets to make.
