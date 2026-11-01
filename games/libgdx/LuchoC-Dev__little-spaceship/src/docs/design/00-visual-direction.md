# Visual direction

Decided on 20/08/2026, first half of [phase 06](../plan/06-presentation/plan.md). It closes the
open item *"sprite sizes, which the visual direction has to settle before real art is drawn"* in
`../STATUS.md`.

This is the art lane's contract. Everything drawn for the game — level 1 and the four stages after
it — obeys these five documents:

| # | Document | Settles |
|---|---|---|
| 01 | [Palette](01-palette.md) | the 32 colours, split into two disjoint sets |
| 02 | [Sprite sizes](02-sprite-sizes.md) | pixel dimensions and hitbox radii per archetype |
| 03 | [Typography](03-typography.md) | the two bitmap fonts and how text is drawn |
| 04 | [HUD layout](04-hud-layout.md) | every widget, at fixed pixel coordinates |
| 05 | [Legibility rules](05-legibility-rules.md) | what must be distinguishable, and from what |

Sprite sizes are synchronisation point 1: phase 03 writes hitboxes from
[02](02-sprite-sizes.md) and no sprite is drawn before it.

## The tone

An experimental human ship over a city at night during the first hour of an invasion. Cold,
industrial, unlit — the light in the frame comes from fires below and from what is shooting at you.
The reference is late-80s arcade pixel art with a modern restraint: few colours, hard edges, no
gradients, no glow that is not drawn by hand.

Human technology reads as **grey-blue metal with cyan running lights**. Alien technology reads as
**violet mass with no visible cockpit**. The player is the only cyan silhouette on screen; enemy
fire is the only magenta. That single sentence is the whole visual system, and everything below is
its enforcement.

## The rule that generates the rest

**Legibility before beauty.** In a shoot 'em up a beautiful level where bullets are hard to see is a
broken level.

It is enforced structurally, not by taste. The palette is split into two sets that do not overlap:
what backgrounds may use, and what gameplay may use. A background cannot be too bright to sit
behind a bullet because the colours to make it that bright are not available to it. The reserved
magenta band belongs to enemy fire and nothing else, in every stage of the campaign.

The separation is measured, not asserted: the brightest background-legal colour sits at L\* 44.9 and
the darkest gameplay colour at L\* 48.1. [The palette document](01-palette.md) carries the table and
the script that checks it.

## Surviving the whole campaign

The palette was built for five stages, not for one city. Level 1 uses less than half of it.

| Stage | Setting | Background ramps it draws from |
|---|---|---|
| 1 | Invasion of Earth — city at night | neutrals, blues, teal, warm embers |
| 2 | Earth orbit | neutrals, blues, a thin warm terminator |
| 3 | Defence of the Moon | neutrals only, blues for shadow and starfield |
| 4 | War against the entities | violets, maroons, dark neutrals, alien green |
| 5 | Last defence of Earth | stage 1 ramps, warm-dominant and more ruined |

Stage 3 is the trap and it is worth naming: **the Moon is drawn as mid-grey rock, never white**.
White is a gameplay colour. A lit lunar surface at N4 reads perfectly as bright rock next to a
sky at N1, and leaves the top of the value range free for the things that kill you.

Stage 4 is the other trap. Biomechanical tissue wants pink, and pink is spent. It is drawn in the
violet band (V1–V3) and the maroon-brown band (M1–M2) instead, which read as organic without
entering the reserved hue.

## What this direction does not decide

- The boss's look and phases. Open in `../planning/08-decisions-and-open-items.md`, resolved in
  phase 07. [02](02-sprite-sizes.md) fixes its footprint and how it collides, nothing else.
- Content identifiers. The sprite ids proposed in [02](02-sprite-sizes.md) are a proposal for
  synchronisation point 2, in phase 04.
- Audio, animation timings beyond frame counts, and the Skin's own decoration.
