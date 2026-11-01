# Gas System

## Spread Rules
- Turn 1: source tile, thickness 3
- Turn 2: all adjacent tiles (obstacle-aware), thickness 2
- Turn 3: one more ring out, thickness 1
- Turn 4: dissipates
- Obstacles slow spread (gas takes longer to route around them)
- Effect is a **per-turn tick**, scaled by thickness

## Gas Types

| Gas | Effect | Special |
|-----|--------|---------|
| Poison cloud | tick damage | condense → damage burst |
| Smoke | blinds enemies (opaque) | fire contact → ignites, AoE burn, clears smoke |
| Frost mist | freeze stacks | dampens fire spells passing through (not a full block) |
| Flammable gas | — | fire contact → explosion + blowback |
| Mist | — | partially dampens fire spells |

## Spell Interactions
- **Mist / Frost mist** reduce fire spell damage proportional to thickness — partial dampening only, never a full block
- **Flammable gas + fire** = explosion with **blowback** that can hit the mage row (the only reliable way gas endangers mages)
- **Smoke** can blind mages too if they fire through it, causing spells to scatter

## Mage Danger
- Mages sit outside the battlefield — gas does not normally reach them
- **Explosion blowback** is the primary exception: detonating flammable gas sends a shockwave one row back into the mage row
- Toxic/condense burst was considered but deprioritised

## Key Spell: Condense
- Collapses all spread tiles of a gas cloud back to the source at full thickness 3
- Natural fit as an **alchemy catalyst** — combine with any gas spell for a concentrated burst payoff

## Architecture Notes
- Needs a new `field_statuses: Dictionary` (key = `Vector2i`) on `BattleState`
- Spread logic lives entirely in `StatusData.on_turn_end` — must be pure and deterministic
- Traverse grid in canonical order (e.g. by position) to avoid replay divergence
- Obstacle interaction reads from `BattleSetup` (read-only), position overrides from `BattleState.enemy_positions`
