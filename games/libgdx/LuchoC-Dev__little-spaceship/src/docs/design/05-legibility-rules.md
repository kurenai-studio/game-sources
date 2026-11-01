# Legibility rules

What the player must be able to tell apart, from what, and how it is verified. These are not
aspirations: each one is either enforced by the palette, checkable by a script, or has a procedure
next to it.

## The priority order

When two of these fight, the one higher up wins. Every rule below exists to protect this order.

1. **Enemy fire.** Where it is, where it is going, and how big it is.
2. **The player's ship.** Its exact position inside a crowd.
3. **Player state.** Invulnerable, shielded, carrying an attachment.
4. **Enemies.** Which archetype, and whether it is about to shoot.
5. **Pickups.** That one exists and which one it is.
6. **The world.** That a city is burning underneath.

The world is last on purpose. It is the thing with the most pixels and the least to say.

## Colour

**R1. Two disjoint sets.** Backgrounds draw from the background-legal colours, gameplay from the
gameplay-only ones. No colour is in both. [The palette](01-palette.md) carries the lists and
`palette/check.py` proves they do not overlap.

**R2. The reserved band.** Hues from 320 to 350 degrees belong to enemy fire, in every stage of the
campaign. Nothing else uses them — not a background, not an enemy hull, not an explosion, not a
pickup, not the HUD.

**R3. The value gap.** No background pixel above `L* 45`; every gameplay sprite carries pixels at
`L* 48` or above. Enemy fire clears the gap by 13 points of lightness with its body colour and by
45 with its core.

**R4. Never hue alone.** Anything the player must distinguish differs in at least two of *hue*,
*value* and *shape*. The weapon level changes projectile count and width, not colour. Player fire is
cyan **and** elongated; enemy fire is magenta **and** compact. A player who cannot separate the two
hues still reads the game from the shapes.

## Outlines

**R5. Every gameplay sprite carries a 1 px outline.** `N0` for everything, `H1` for enemy fire.
This is the single most effective rule in the document: it is what lets a bright bullet stay
readable over a fire, and a dark hull stay readable over a night sky, without constraining either.

**R6. The outline is closed.** No gaps, no partial outlines, no outlines that skip the bottom edge.
A sprite with a broken outline dissolves into whatever is behind it at the one moment it matters.

## Backgrounds

**R7. Quiet by construction.** Adjacent areas of background differ by at most two steps of their
ramp. A background that has high internal contrast competes with gameplay even when every colour in
it is legal.

**R8. Detail belongs far away.** The closest parallax layer is the plainest. Detail, texture and
dithering live in the distant layers, where they move slowly and read as depth.

**R9. Velocity separation.** No background layer scrolls at or above the speed of the slowest
enemy. Something moving at gameplay speed reads as gameplay, whatever colour it is.

**R10. Ambient events stay out of the way.** Explosions, aircraft and collapsing buildings in the
background are drawn from background-legal colours only, never enter the reserved band, and never
cross the vertical third of the playfield where the player usually sits.

## Motion and flashes

**R11. Fire is telegraphed.** Every enemy shot is preceded by a muzzle flash on the shooter, at
least 2 ticks before the projectile exists. A bullet that appears without warning is unreadable no
matter how bright it is. **Not built** — `EnemyWeaponSystem` creates the projectile the tick the
cooldown reaches zero, and there is no muzzle flash anywhere in the project. The boss is the
exception and it obeys the spirit of the rule: `06-boss-presentation.md`'s three-beat tell runs for
0.75 s before every volley.

**R12. No full-screen flash lasts more than 2 ticks**, and none is pure `N7`. This is
photosensitivity and legibility at once: a white frame over the playfield hides every bullet the
player is about to dodge.

**R13. The bomb clears visibly.** Projectiles removed by a bomb play a 3-frame dissipation rather
than vanishing, so the player can see what was cleared and what was not. **Not built** —
`BombSystem` marks them and `CleanupSystem` removes them the same tick, so they vanish.

**R14. Nothing kills without a sprite.** No invisible hitbox, no off-screen damage, no hazard
communicated only by sound.

## Sizes and shapes

**R15. Enemy fire is never smaller than 5x5**, with a core of at least 1 px in `H3`. Sizes are in
[02](02-sprite-sizes.md).

**R16. Silhouettes are unique.** Each of the six archetypes is identifiable filled with flat black
at 1x, with no colour and no detail. See the test below.

**R17. Pickups do not read as bullets.** Green, larger than any bullet, drifting slowly downwards
with a 4-frame float. Hue, size and motion all separate them; any one of the three would be enough.

## Which of these are actually enforced

Added 26/08/2026, because until then these fifteen rules were written in one voice and only some of
them held. **R1, R2, R3, R5, R15, R16 and R17 are enforced** — by the palette's disjoint sets, by
`palette/check.py` and `lint-art.py`, and by `mockups/check.js`, which rejects a sprite at build
time. **R11 and R13 are not built**, and each says so above. The rest are drawing rules with no
automated check, held by whoever draws.

## How it is verified

None of this counts as checked until it has been run on the real thing.

**The palette check.** `python docs/design/palette/check.py` — proves R1, R2 and R3 hold for the
palette itself.

**The art lint.** `python docs/design/palette/lint-art.py <png> background|gameplay|hostile` —
proves a drawn asset stayed inside its set. Run it on every sprite as it is finished, not at the end.

**The silhouette test.** Fill every archetype with `N0` and look at the six shapes side by side at
1x. If two are hard to tell apart, one of them is redrawn. Proves R16.

**The greyscale test.** Screenshot the level at peak density and desaturate it. Enemy fire must
still be among the brightest things on screen, and the player ship must still be findable. Proves
R3 and R4 survive contact with real art.

**The squint test.** The same screenshot, blurred or viewed from across the room. What survives
should be, in order: bullets, the ship, the enemies. If the background survives instead, R7 was
broken somewhere.

**The section sweep.** The phase's acceptance criterion is that enemy bullets are distinguishable
from **every** background in the level. Screenshot each of the level's background sections at peak
density and run the greyscale and squint tests on each. Once, per section, on the real build — not
on one representative screenshot.

## When a rule gets in the way

It will, and the answer is not to bend it quietly. A rule that blocks something worth having is
worth changing here first, with the reason written down, so the next sprite is drawn against the
new rule instead of against a memory of a conversation.

The three that are not negotiable, because the game stops working without them: **R2** the reserved
band, **R3** the value gap, and **R5** the outline.
