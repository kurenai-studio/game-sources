# Master context — space game

## Purpose of this package

This package consolidates the initial discovery and planning stage of the project. The source is the full conversation **“Planificación juego espacial”** (`6a8328f6-a57c-83e9-80f8-c07edb4191dd`), from the first turn `88a1854a-0636-4737-bc11-9d995c2895bb` to the last turn `a2bce64f-3161-4d77-9376-65c2aef70132`.

It is not yet a closed architecture nor an implementation plan. It deliberately distinguishes between:

- **Confirmed:** decision stated and sustained throughout the conversation.
- **Provisional:** direction accepted in order to move forward, but subject to testing or balancing.
- **Open:** alternative not yet chosen, or aspect not yet defined.
- **Out of scope for the MVP:** part of the vision, but not of the first publishable release.

## Executive summary

The project —repository **`little-spaceship`**— will be a **level-based vertical shoot 'em up**, single-player and local, developed from scratch. It picks up the emotional DNA of an old space game by the author —ship, threats from above, dodging, shooting and score—, but reuses none of its code, architecture or assets.

The goal is to create a functional product, publishable and presentable in a portfolio, reflecting the author's current level through architecture, tests, CI, performance, documentation, art and deployment. Java will remain the main language. The platform was decided after the technical prototype: **Java 17 + libGDX + Gradle + gdx-teavm**, publishing to the browser with JavaScript and with a desktop target sharing the same core. The repository will stay private during initial development; opening it will be evaluated upon reaching the MVP or the final product.

The MVP will be a small but finished experience: menu, options, selection of a basic ship, one complete level on Earth, enemies and waves, power-ups, one attachment, score, HUD, boss, audio, animations and victory/defeat screens. It will not include profiles, saving, checkpoints, shop, difficulty levels or alternative modes.

The full vision contemplates a five-stage campaign, 3–5 levels per stage, hangars, permanent unlocks, three profile slots, autosave, Survival and Endless modes, meta-progression and a possible second, offensive campaign.

## Recommended reading order

1. `01-vision-and-scope.md`: product identity and scope boundaries.
2. `02-mvp-functional-spec.md`: what the first release must contain.
3. `03-game-systems.md`: gameplay rules and persistent/temporary states.
4. `04-campaign-and-levels.md`: narrative structure and level design.
5. `05-progression-modes-and-saving.md`: extended campaign, profiles and future modes.
6. `06-platform-and-technical-validation.md`: reasoning prior to platform validation.
7. `07-references-and-asset-constraints.md`: relationship with old projects and licences.
8. `08-decisions-and-open-items.md`: doubts, contradictions and pending verifications.
9. `09-source-map.md`: traceability back to the original turns.
10. `10-mvp-initial-values.md`: starting values and operational decisions for building the MVP.
11. `11-technical-prototype-results.md`: spike result and platform decision.
12. `12-architecture.md`: project structure, ECS, content and tests.
13. `13-working-with-agents.md`: agent roster, memory and division of work.

## Language

The planning documentation has now been **translated to English**, and stays in English from here on.

Everything else that lives in the repository is also written **in English**: code, comments, logs, JSON keys, agent definitions and `CLAUDE.md`.

The only Spanish that remains is the conversation with the user, plus the verbatim transcript kept in `docs/sources/`, which is left untouched on purpose because it is evidence of a real conversation.

## Guiding principles

- Specify the experience first; then validate the platform; then define the architecture; finally implement.
- The new game is neither a remake nor a technical restoration.
- Variety must emerge from combinable systems —ships, patterns, trajectories, formations, attachments— and not only from raising stats.
- The MVP must feel publishable, not like a demo of boxes and placeholders.
- The campaign is the main path and must teach/unlock the rest of the game.
- Web is desirable because of how easy it is to open a link and play, but it must not deform the design nor impose disproportionate complexity.

## Source and traceability

The source conversation includes functional decisions, assistant proposals and points the user deliberately left open. When an assistant proposal was not explicitly confirmed, this package keeps it as a recommendation or alternative, not as a final decision.
