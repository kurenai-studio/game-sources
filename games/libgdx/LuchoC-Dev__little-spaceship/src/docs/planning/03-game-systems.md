# Game systems

## Session and run model

A **run** begins when the player starts from a save point, hangar or campaign checkpoint, and continues while at least one life remains. It may span several levels.

When all lives are lost:

- the run ends;
- the corresponding temporary state is lost;
- restarting from the last safe point starts a new run.

A run does not necessarily mean playing the whole campaign from stage 1. Safe points allow splitting it into balanceable sections.

## Progression states

### Permanent in the profile

- Unlocked ships.
- Unlocked attachment types.
- Levels/stages reached or completed.
- Unlocked modes.
- Permanent shop content.
- Records and relevant scores.
- Challenges or secrets, if implemented.

### Persistent within a run

- Remaining lives.
- Power-ups kept between levels according to the final difficulty rule.
- Bombs/temporary charges.
- Equipped or found attachment.
- Run currency.

### Initial configuration of a new run

- Early stages: base state.
- Advanced stages: a minimum initial loadout defined by the checkpoint so the player does not enter underpowered.
- High/hardcore difficulties: may remove or reduce those aids.
- Permanently unlocked content remains available to select in the hangar.

This default configuration is used only when the player chooses to **start a new run from that checkpoint**. It does not replace the state of a suspended run.

### Continuing an existing run

When the player uses Save and quit and then Continue:

- the location or section resumed corresponds to the last safe checkpoint;
- the state the player had when saving is restored: lives, unconsumed power-ups, bombs/charges, equipped attachment, run currency and the rest of the run data;
- the checkpoint's default loadout is not applied, because this is not a new run.

The conceptual separation is: **Continue = recover an existing run**; **Start from a checkpoint = create a new run balanced for that section**.

## Survival and damage by mode

### Main campaign

- Lives system.
- The focus is on dodging and avoiding hits.
- Defensive power-ups and attachments can absorb damage before consuming a life.
- Respawn with temporary invulnerability.
- All damage taken grants temporary invulnerability, including losing the shield or the attachment, with a shorter duration than that of respawn.
- Crashing into an enemy damages the player and destroys weak enemies; heavy ones withstand the impact.

### Survival

- An HP/accumulated attrition model was proposed.
- The rule was not designed in detail and must be validated when the mode is implemented.

### Endless

- A hybrid HP + lives model was proposed.
- It also remains a future direction, not a closed specification.

## Power-ups

Power-ups improve existing capabilities or deliver resources/temporary protection. Their effect may vary depending on the ship.

### Types considered

- Shot power/count.
- Shield.
- Extra life.
- Special ability ammunition/charge.
- Temporary invulnerability.

### Persistence

- The weapon upgrade can stack levels up to a configurable maximum.
- Shield and extra life are consumed by their own rules.
- Ammunition remains until the ability is used.
- Invulnerability lasts a set amount of time.
- They can be kept when changing level within the same run.
- On normal difficulties, losing a life does not remove power-ups that have not yet been consumed by their own rule.
- The shield can indeed disappear when absorbing the hit, and invulnerability ends when its duration runs out.
- Higher difficulties may modify this persistence; the exact rule is left to the design of the difficulty system.

### Appearance

- Preferably designed, not governed by opaque probabilities.
- A specific enemy within a wave can drop a power-up without making that a universal property of the archetype.
- Destructible structures may contain resources.
- The level can guarantee upgrades after a hard section or before a peak.

## Attachments

Attachments add new systems or weapons to the ship. They differ from power-ups because they change the way you play more deeply.

### Examples

- Missiles.
- Laser.
- Countermeasures that destroy enemy shots.
- Future possibilities: drones, turrets, side weapons or alien/hybrid technology.

### Current rules

- A single active slot in the MVP.
- Several slots are possible for future ships or modes. Attachments act automatically or semi-automatically, so stacking several does not create control conflicts.
- Availability and compatibility may depend on the ship.
- They are rarer than power-ups.
- They can be found by defeating sub-bosses, bosses, exceptional units or by interacting with an installation/base.
- Finding one may allow using it immediately and permanently unlock its type.
- Unlocks are managed freely upon reaching a hangar.
- The attachment is lost when taking damage and when losing a life. It absorbs the hit that destroys it, avoiding that life loss.
- It is kept when moving to the next level within the same run, just like power-ups.
- By default all attachments share the same durability, but that value is data per attachment and not a rule fixed in code: it must be possible to raise it for cases such as a protection attachment.

### Defensive priority

When several layers coexist, the confirmed order is:

1. Invulnerability.
2. Shield.
3. Attachment.
4. Life.

The attachment acts as a defensive layer: it absorbs the hit and is destroyed before a life is consumed. Durability is configurable per attachment; the concrete catalogue of categories is still pending design.

### Introduction philosophy

They are introduced when the level makes their usefulness evident, without turning the module into a mandatory key except in special cases.

## Ships

Each ship must have its own gameplay identity. Possible differences include:

- movement speed and precision;
- fragility or resistance depending on the mode;
- rate of fire, shot count and damage;
- sustained, manual, slow or charged shot;
- special ability;
- interaction with power-ups;
- compatibility with and use of attachments.

The concrete characteristics of each ship will be iterated during development. The narrative must not depend on immutable stats.

## Unlocks

- Main ships: natural progress, bosses or end of stage.
- Common attachments: discovery in levels, special units or sub-bosses.
- Special ships/attachments: challenges, hidden routes, score, not dying or optional objectives.
- Avoid requirements based purely on grind.
- Anything newly unlocked is saved immediately, but is changed/equipped freely at the next hangar.

## Hangar and resupply

### Main hangar

- Normally appears at the end of a stage.
- Ship selection/change.
- Management of unlocked attachments.
- Possible purchases with the run currency.
- Safe point for saving/continuing.

### Resupply point

- May appear between levels or inside a long one.
- Offers a subset of the options.
- May be represented as a carrier, base or allied station.

## Score and economies

### Score

- Arcade performance metric.
- Present from the MVP onwards.
- May feed records and future rewards.

### Run currency

- Obtained during the run.
- Only used in hangars or equivalent points.
- Lost when the run ends.
- If starting from an advanced stage, a base amount may be granted.
- The name is not defined yet.

### Meta-economy

- Permanent shop limited to skins and some special content.
- Using accumulated score was considered.
- It is not desirable for spending to reduce a historical record.
- Suggested alternative: a historical score separate from credits derived from the score.
- The final decision was left open.

## Enemy and wave design

The following concepts must be independent:

- archetype/enemy;
- base stats;
- trajectory;
- shot pattern;
- formation;
- spawn event;
- reward/drop.

In early levels the patterns will be legible and progressive. In advanced levels they can be combined, reuse known enemies on new trajectories, add reactivity or increase pressure.

## Intensity curve

Each level should be designed with a relative curve of pressure over time:

- introduction;
- escalation;
- peaks;
- rests;
- recombination of threats;
- climax/boss.

Pressure can be modified through quantity, projectile density, speed, resistance, formation, obstacles, space and simultaneity. It was proposed to create later on a tool or graphical representation for designing that curve.
