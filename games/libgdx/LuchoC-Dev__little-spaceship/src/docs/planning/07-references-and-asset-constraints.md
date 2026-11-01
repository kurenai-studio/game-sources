# Historical references and asset constraints

## Relationship with the old projects

The earlier projects serve as an emotional and historical reference. They are neither a technical base nor an asset repository.

The new project:

- starts from scratch;
- does not copy architecture or classes;
- does not attempt to reconstruct lost versions;
- is not obliged to preserve old rules;
- may keep only the arcade space shooter DNA.

## Repo reported as V3

Repository: `https://github.com/LuchoC00/ProyectitoNavecita`

What was inspected during planning:

- Java 17 with Maven.
- 800×600 window.
- Title “Lost Galaxian - Grupo 3 - v1”.
- External dependency `entorno.jar`.
- Background images.
- No game logic or entities implemented in what was published.
- README named “Proyecto jueguito 2.0”.
- The public version does not clearly match the remembered numbering.
- Not enough visible history to reconstruct versions 2–4.

Conclusion: it offers no usable functional base.

## Playable V1 repo

Repository: `https://github.com/LuchoC00/Tp-Progra1`

Observed characteristics:

- Fixed 800×600 screen.
- Ship near the bottom edge and centred.
- Horizontal movement with the arrow keys.
- Visual tilt when moving.
- Asteroids from above or from the sides with diagonal trajectories.
- Vertical shot, designed for one active missile at a time.
- Points for destroying asteroids.
- A score target as the victory condition.
- Health bar above the ship.
- Aura/shield while holding Shift.
- Classes or resources planned for enemies and enemy shots that were not integrated.
- Several important calls commented out in the public `tick`.

Conclusion: it is useful to understand the origin and the arcade tone, not to infer a final design or reuse code.

## Old assets

They must not be reused. They include material associated with Star Wars and a background attributed to Lucasfilm, without an adequate licensing basis for a new publication.

## Asset policy for the new project

- Prioritise in-house pixel-art.
- Prefer CC0 assets when external resources are used.
- Accept CC-BY or other compatible licences only with documented attribution.
- Record author, source, licence, version and modifications for each external asset.
- Review the licences of fonts, music, effects, sprites, icons and libraries separately.
- Do not assume that “free” means permitted for redistribution or portfolio use.
- Keep credits even if a credits screen does not yet exist in the MVP.

## Reference, not dependency

Future design may pay homage to general elements —ship position, descending threat, shield, score—, but it must rebuild them as its own systems, coherent with the new vision.
