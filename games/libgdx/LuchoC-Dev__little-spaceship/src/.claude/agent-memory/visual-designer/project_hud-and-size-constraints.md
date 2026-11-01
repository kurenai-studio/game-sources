---
name: hud-and-size-constraints
description: What the code already decided for me about sprite shape, hitboxes and the HUD
metadata:
  type: project
---

**Why:** the phase plan asks for sizes without saying what shape the code can collide with, so these were found by reading `core/` rather than by reading `docs/`.

**How to apply:** check them before sizing anything new; a sprite drawn against the wrong assumption forces hitbox rework across the code lane.

Constraints the visual direction inherited from code that already exists, none of which the phase
plan mentions.

**`core.domain.component.Collider` is a circle with a radius and a layer — no offset, no rectangle.**
So a hitbox is always concentric with its sprite, and the art has to put the visual mass at the
centre. Anything outside the circle must be thin and read as secondary, or the player shoots a wing
and nothing happens. It is also why the boss cannot be one entity: a single circle over a 119 px
boss would swallow the gaps the player flies through, so it is five colliding parts moved together.

**`SpriteVisitor` passes no size.** The adapter resolves a `SpriteId` to a region and the region's
own dimensions decide what is drawn, so the sizes in `docs/design/02-sprite-sizes.md` are only real
once the art matches them. Nothing in the code will catch a sprite drawn at the wrong scale.

**Sprites are centred on their `Transform`, which is why every dimension is odd.** An even width
straddles two pixel columns and the ship visibly wobbles crossing a half-pixel.

**The playfield is 208 px of a 480 px screen.** That is the argument that settled the boss bar:
horizontal across the playfield would cover 208 px of play space at peak density, so it is vertical
in the right margin instead. The margins are 136 px each and mostly empty — the constraint is never
width, it is that anything drawn there competes for attention with the playfield.

Related: [[palette-invariants]]
