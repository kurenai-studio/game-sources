# MVP functional specification

## Goal

Deliver a single fully playable, polished and publishable level, able to show the core loop, the audiovisual presentation and the future direction of the product.

The MVP is not the full campaign. It is a vertical slice: every system needed to play and finish the level must work, even if its content is minimal.

## Complete flow

1. Game start.
2. Main menu.
3. Ship selection/building screen.
4. Selection of the only basic ship available.
5. Level 1.
6. Victory on defeating the boss while keeping at least one life, or defeat on losing all lives.
7. The corresponding screen with simple options.

## Menu and screens

### Main menu

- Play.
- Options.
- Quit. **Its meaning now depends on the target** — see "Menu and screens, 01/09/2026" in
  `08-decisions-and-open-items.md`. On desktop it exits (`Gdx.app::exit`). On the web target a browser
  tab cannot close itself, so it opens `game/screen/FarewellScreen.java` with a way back to the menu.
  The entry itself, its label and its position are the same on both.

Locked future modes and “coming soon” buttons will not be shown.

### Ship selection/building

- One selectable basic ship.
- Presentation of its main characteristics.
- The screen must be conceptually prepared to add ships.
- Showing silhouettes or future slots is optional; there will be no unlocking, purchase or deep customisation in the MVP.

### Options

- Master volume.
- Music volume.
- Effects volume.
- Enable/disable mouse control.
- No key remapping.

### Pause

- Simple symbol or button.
- Freezes gameplay, enemies, projectiles, relevant animations and timers.
- ~~No full pause menu.~~ **Superseded on 01/09/2026** — see "In-game options, 01/09/2026" in
  `08-decisions-and-open-items.md`. The panel offers RESUME, OPTIONS and QUIT TO MENU, and OPTIONS
  swaps the panel's contents in place for the three volume sliders rather than opening a screen.
  `game/screen/PlayScreen.java`. It is still not a full menu: only volume is reachable mid-run.

### Defeat

- Retry the level.
- Return to the menu.

### Victory

- Brief animation or screen.
- Return to the menu.
- Retrying is optional, not a requirement.

## Basic ship

### Movement

- Free movement on two axes inside the playable area.
- Normal speed fast enough to reposition.
- Slow/precise movement key.
- No dash or special dodge manoeuvre.

### Attack

- Automatic/sustained main shot.
- The weapon upgrade increases the number of projectiles of the basic ship.
- The upgrade level must be recognisable by the shape, count or size of the shot, without requiring a numeric indicator.
- There must be a configurable maximum; the starting value is in `10-mvp-initial-values.md`.

### Hitbox and combat identity

- The game is an intermediate-density shoot 'em up, neither a bullet hell nor a purely traditional arcade game.
- The player's hitbox is smaller than the sprite, but not a single point, and it is not shown on screen.
- Projectile density is moderate: dodging is done by reading trajectories and positioning, with slow movement as the precision tool in demanding moments.
- Legibility takes precedence over quantity: the player must always be able to tell what can hit them.

### Special attack

- A bomb that removes most threats/projectiles on screen and deals heavy damage to resistant enemies.
- It works as both an offensive and an emergency resource.
- The initial amount depends on the ship's design. Starting values in `10-mvp-initial-values.md`.

### Survival

- Arcade lives system.
- Three initial lives, with a maximum reachable through the extra life power-up.
- On losing a life, the ship respawns near the area where it was destroyed.
- There is temporary invulnerability after respawn.
- Any damage taken grants temporary invulnerability, not only death. Losing the shield or the attachment also grants those grace frames, preventing several hits from chaining in an instant.
- The grace frames from absorbed damage are shorter than those from respawn; both values are configurable.
- On normal difficulty, losing a life **does not automatically remove persistent power-ups**.
- Each power-up keeps its own consumption condition: for example, the shield can be lost when absorbing damage, and invulnerability ends by time.
- On higher difficulties a harsher rule may apply; it still has to be defined once the difficulty system exists.
- The confirmed defensive order is: **invulnerability → shield → attachment → life**.

### Collision with enemies

- Crashing into an enemy damages the player and consumes the defensive layer that corresponds according to the confirmed order.
- Weak enemies —basic, light and fast— are destroyed in that crash; tanks and heavy carriers are not.
- The impact triggers temporary invulnerability from damage.
- This rule leaves the ramming enemy archetype planned for later stages ready to be added.

## Controls

### Keyboard

- Arrows for movement.
- One key to shoot.
- One key for slow/precise movement.
- One key for bomb/special ability.

### Optional mouse

- Move the ship.
- Shoot.
- Launch the special ability.
- Can be enabled or disabled from Options.
- Keyboard and mouse work simultaneously and additively when the mouse is enabled: both contribute a movement vector and those vectors are summed, so opposite directions cancel out.
- The mouse is relative, not positional: it moves the ship by cursor displacement, it does not take the ship to the pointer's position.

Gamepad and mobile touch controls are not included in the confirmed scope.

## MVP power-ups

- Weapon upgrade.
- Shield.
- Infrequent extra life.
- Bomb ammunition/charge recovery.
- Temporary invulnerability.

Scenario obstacles are decorative in the MVP and do not collide; only destructible structures interact with gameplay.

Drops are controlled from the level design. An enemy type does not always drop the same thing: a specific instance within a wave can be marked to deliver an upgrade. There can also be destructible structures containing resources.

## MVP attachments

- Only one attachment active at a time. The MVP does not deliver a second one, so that case does not arise.
- It adds a new capability, not a simple numeric increase.
- Examples considered: missiles, laser or countermeasures.
- It must be rarer than a power-up.
- In level 1 it is delivered by the strong encounter before the rest, so it arrives just before the final escalation and the boss.
- In future levels it may come from sub-bosses, exceptional units, structures/bases or designed events.
- It absorbs one hit and is destroyed before a life is lost.
- It is also lost when a life is lost.
- Confirmed absorption order: invulnerability → shield → attachment → life.

## Level 1

### Narrative context

Earth suffers the first big alien wave. Present-day forces try to defend a city, base or important place, but their technology is insufficient. An experimental ship launches from a secret base to contain the attack.

### Macro pacing

1. Brief launch/take-off animation.
2. Between 5 and 10 seconds of quiet travel.
3. Background environmental events: attacks, meteorites, human aircraft, defences and destruction.
4. Appearance of basic enemies.
5. Progressive introduction of formations and new archetypes.
6. Pressure escalation.
7. Strong threat or encounter before the end.
8. A 5–10 second rest.
9. A new, faster escalation.
10. Boss.
11. Victory or defeat.

The sequence is provisional and will be adjusted with an intensity curve, not as a rigid list.

### Minimum enemy roster

- Basic: weak, low health and slow shot.
- Fast light: high mobility and a simple/different shot.
- Evolved basic or shooter: similar to the basic one with a higher rate of fire.
- Super-fast: main threat through movement; shoots little.
- Tank: slow and resistant.
- Heavy carrier: very slow, high health, does not shoot and spawns basic enemies periodically.
- A simple, legible boss appropriate for a first level; patterns and aesthetics still open.

Level 1 enemies use relatively legible patterns, but their trajectories and formations must be reusable or combinable with other types in future levels.

## Score

- Simple arcade system.
- Points are obtained mainly by destroying enemies and completing the level.
- The current score is displayed.
- It does not work as currency in the MVP.
- No confirmed combos, multipliers or persistent economy.

## HUD

- Remaining lives.
- Bomb/special ability charges.
- Current score.
- Power-up status where applicable.
- Equipped attachment, if any.
- Invulnerability status communicated visually.
- Boss health only during its fight.
- Clear feedback for hits and for losing upgrades.

Minimap, enemy counter, detailed stats and a permanent level progress bar are not included.

## Audiovisual presentation

- Pixel-art with a visual direction close to the definitive one.
- Animations for movement, shooting, appearance, impact, explosion, bomb, life loss, pickups, victory and defeat.
- Sound effects for shots, impacts, explosions, power-ups, bomb and UI.
- Main level music.
- Music change when the boss begins.
- Dynamic changes during other difficulty peaks are optional polish.

## Explicit MVP exclusions

- Difficulty selector or system.
- Checkpoints.
- Profiles and save slots.
- Save and quit / Continue.
- Functional hangar and economy.
- Permanent shop.
- Real unlocks.
- More than one playable ship.
- Full campaign.
- Survival and Endless modes.
- Key remapping.
- Dash.
- Gamepad and touch controls.

Systems must avoid becoming rigidly coupled to the MVP's single set of content, but future features will not be implemented without a real use.

## Functional acceptance criteria

- The player can go through the complete flow without developer tools.
- The level can be won and lost.
- Pause, options and restart work correctly.
- The boss marks a distinct climax with its own music and HUD.
- The controls are legible and the precise mode allows dodging.
- The level introduces archetypes and then combines them.
- Power-ups, score and attachment are communicated correctly.
- The audiovisual side does not rely exclusively on placeholders.
- The chosen build can be published and run reproducibly.
