# Beyond the MVP

Sketched, not planned. These are directions, and each becomes a real plan when its moment arrives — with real gameplay to inform it, which is exactly what is missing now.

The full vision is in `docs/planning/01-vision-and-scope.md`, `04-campaign-and-levels.md` and `05-progression-modes-and-saving.md`.

## Immediately after the MVP

**Finish stage 1.** Three to five levels, reusing the archetypes of level 1 in new trajectories and formations. This is the first real test of whether the content pipeline pays off: if a new level is mostly JSON, the architecture worked.

**Second ship.** The point is not a stat change — it is identity through behaviour. A charged shot or a manual one plays differently from sustained fire, and it is what proves ships are more than numbers.

**More attachments.** Missiles, laser, countermeasures. Each adds a capability rather than a multiplier.

## Progression

**Three profile slots**, with global settings shared between them, so changing profile never changes the volume the same person chose.

**Saving**: autosave at the end of a level or stage, Save and quit, Continue. The distinction to preserve is the one already decided — Continue recovers an existing run, while starting from a checkpoint creates a new one with a default loadout.

**Hangar** at the end of each stage: switch ship, equip unlocked attachments, spend the run currency.

**Unlocks** through natural progress, with the rarer ships and attachments behind specific challenges rather than grind.

## Campaign

Five stages: Earth invasion, orbit, the Moon, the war against the entities, and the last defence of Earth. The tonal shift matters as much as the setting — stage 1 is "we are being invaded", stage 5 is "this is the last line".

The transition between stages 3 and 4 is the act break: a supership that, when destroyed, releases something alive.

## Modes

**Survival**, unlocked after stage 1: the campaign cycling endlessly, stages repeating visually while difficulty keeps climbing.

**Endless**, unlocked after the campaign: a single continuous session.

Both need the damage model settled — HP for Survival, HP plus lives for Endless were suggested but never confirmed.

## Technical work that will come due

**A spatial grid for collisions**, if any level ever needs it. Already written and measured in the spike: it gave a 10× improvement in the worst scenario. It stays unused until profiling justifies it.

**Object pooling**, same criterion: when a profiler asks for it, not before.

**Save serialisation**, which brings the first real persistence problem: what to do with a corrupt or version-incompatible save.

## What is deliberately not decided

The game's name, the world, its factions and characters. The exact number of levels per stage. The presentation format between stages. Whether there is a second, offensive campaign.

None of it blocks anything, and deciding it now — without a playable game — would be guessing.
