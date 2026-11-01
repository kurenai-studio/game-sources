# Phase 06 — Presentation

**Lane:** art and code · **Owners:** `visual-designer`, `game-presentation` · **Depends on:** 03 · **Target:** days 1-6, integrated on day 5

## Before you start

**Read, in this order:**

1. `docs/planning/02-mvp-functional-spec.md` — what the HUD must show, and the screen flow.
2. `docs/planning/01-vision-and-scope.md` and `04-campaign-and-levels.md` — identity and tone.
3. `docs/planning/10-mvp-initial-values.md` — resolution and scaling policy.
4. `docs/planning/07-references-and-asset-constraints.md` — asset licensing rules, which apply from the first asset.

**Do not re-decide:** there is no HTML and no CSS here. Styling lives in a Skin, layout in tables, typography is a bitmap font. Design by counting pixels.

**This phase gates the schedule.** It is the only one whose output cannot be accelerated by adding agents.

## Goal

The art of level 1 and everything the player reads on screen. This is the phase that runs in **its own lane from day one**, because producing sprites never requires reading code.

Near-final art, not placeholders. Not necessarily the definitive art — but close enough that the MVP does not look like a prototype.

## Preconditions

For the visual direction: nothing, it starts immediately.
For integration: phase 03, so there is something to draw into.

## Tasks

### Visual direction — day 1, blocks everything else

1. **Palette.** Closed, with the legibility rule built in: enemy bullets use a value and hue no background may repeat.
2. **Sprite sizes** per archetype, in pixels. The code lane needs these for hitboxes — this is synchronisation point 1.
3. **Bitmap typography.** Roughly 5×7 px per glyph at this resolution.
4. **HUD layout** in the side margins: lives, bombs, score, power-up state, attachment, and the boss bar during its fight.
5. **Legibility rules** written down, not implied: what the player must distinguish at all times, and against what.

### Art production — days 2-5

6. Player ship with its animations: idle, tilt, thrust, hit, explosion.
7. The six enemy archetypes with their own explosions.
8. Projectiles: four visible player levels, and enemy fire.
9. Power-ups, the attachment, destructible structures.
10. Background: city under attack, parallax, ambient events.
11. HUD icons and the Skin that styles the widgets.

### Integration — day 5

12. Texture atlas and batching.
13. Screens with `scene2d.ui`: menu, options, ship selection, pause, victory, defeat.
14. Wire the HUD to `WorldView`.

## Acceptance criteria

- Enemy bullets are distinguishable from every background in the level, checked on the real thing and not in theory.
- No fractional scaling anywhere; a checkerboard shows no distortion.
- The HUD shows everything `02-mvp-functional-spec.md` requires and nothing more.
- Every screen in the flow is reachable and returns correctly.
- Assets are in one atlas and the render loop keeps batching.
- Every external asset has its author, source, licence and modifications recorded.
- Nothing on screen is a coloured rectangle standing in for art.

## Risks

**This is the phase that decides whether the week holds.** It is the only one whose output cannot be accelerated by adding agents: sprites take the time they take.

**Licences.** `07-references-and-asset-constraints.md` is explicit — own pixel art first, CC0 when external, CC-BY only with documented attribution. "Free" does not mean redistributable. Record the licence when the asset enters, not at the end.

**Art that lies about size.** A sprite drawn at the wrong scale forces hitbox rework across the code lane. Sizes are fixed on day 1 for exactly this reason.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
