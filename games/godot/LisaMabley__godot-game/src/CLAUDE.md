# godot-game

A Vampire Survivors–style arena survival game built in **Godot 4.7** (Forward+), written in **GDScript**.
The player auto-attacks with abilities, collects experience gems from killed enemies, and picks upgrades on level-up until the arena timer runs out (win) or they die (lose).

## Working in this repo

- Godot 4.7.1 is on PATH as `godot` (a `godot.cmd` shim in `~/.local/bin` pointing at the console build). Use it from PowerShell/cmd (`cmd /c "godot ..."` if needed):
  - `godot --headless --path . --import` loads every scene/script and reports parse errors and broken references. Run it after renames, moves, or `.tscn` edits.
  - Gameplay still needs a human. Ask the user to playtest feel and balance changes.
- Prefer editing `.gd` scripts. `.tscn` / `.tres` files are editor-managed: small, targeted text edits (an exported property, a node path) are fine, but don't hand-author new scenes. Describe the node setup for the user to build in the editor instead. Never invent `uid://` values.
- `README.md` is the human-facing overview. When a change adds or alters a feature, control, or top-level folder, update its Features/Controls/structure sections too.
- Commit messages use a conventional prefix: `feat:`, `fix:`, `bug:`. Lowercase, short.
- Display: 640x360 viewport, stretched to 1920x1080, pixel art (nearest texture filter).

## Layout

- `scenes/main/`: root `Main` scene. Holds the managers, UI, `TileMapLayer`, and two layer nodes found by group: `Entities` (`entities_layer`) and `Foreground` (`foreground_layer`).
- `scenes/manager/`: game-wide logic nodes (arena time/difficulty, enemy spawning, experience/leveling, upgrades).
- `scenes/component/`: reusable components composed onto game objects (see below).
- `scenes/game_object/`: player, enemies, drops, camera. Each in its own folder with `.gd` + `.tscn`.
- `scenes/ability/`: each ability has an `*_ability_controller` (timer-driven, spawns instances, listens for upgrades) and an `*_ability` (the spawned attack with a `HitboxComponent`).
- `scenes/ui/`: HUD, upgrade screen/cards, end screen, floating damage text.
- `scenes/autoload/game_events.gd`: `GameEvents` autoload, the global signal bus.
- `resources/upgrades/`: the `AbilityUpgrade` / `Ability` resource classes. Instances are built at runtime from `Balance.UPGRADES`; there are no `.tres` files.
- `scripts/weighted_table.gd`: `WeightedTable`, used for enemy spawns, upgrade pool, and loot.
- `scripts/balance.gd`: `Balance`, constants-only tuning file (see "Balance" below).
- `assets/potential_sprites/`: unused assets parked for later.
- `theme/theme.tres`: project-wide UI theme (custom font, panel styles).

## Architecture & patterns

- **Composition via components.** Entities are assembled from component nodes wired with `@export` references in the editor:
  - `HealthComponent`: `died`, `health_changed` signals; frees its `owner` on death.
  - `HurtboxComponent` (Area2D): *receives* damage from overlapping `HitboxComponent`s and spawns floating text.
  - `HitboxComponent` (Area2D): *deals* damage; `damage` is set by the ability controller at spawn.
  - Naming follows the standard convention: **hitbox = deals hits; hurtbox = can be hurt.** (These were swapped once on 2026-10-26; older commits use the reverse.)
  - `VelocityComponent`, `DeathComponent`, `HitflashComponent`, `LootDropComponent`, `PickupAnimationComponent`.
- **Global signal bus.** Cross-system events go through `GameEvents` (`emit_*` helper methods wrap each signal). Local wiring uses direct signal connections in `_ready()`.
- **Groups for lookups.** `player`, `enemy`, `entities_layer`, `foreground_layer`, `upgrade_card`, accessed via `get_tree().get_first_node_in_group(...)`. Always null-check the player.
- **Upgrades.** `AbilityUpgrade` resource (`id`, `max_quantity`, `name`, `description`); `Ability` extends it with `ability_controller_scene`. `UpgradeManager` builds one instance per `Balance.UPGRADES` entry in `_ready` (an `Ability` if the entry has `ability_controller_scene`, loaded by path to avoid a preload cycle), keeps `current_upgrades[id] = {resource, quantity}` and a `WeightedTable` pool. When an upgrade hits `max_quantity`, it's removed from the pool. Entries with `unlocked_by` join the pool the first time that upgrade is picked (`_update_upgrade_pool`). Ability controllers react to `GameEvents.ability_upgrade_added` by matching on `upgrade.id`.
- **Difficulty.** `ArenaTimeManager` emits `arena_difficulty_increased` every 5s; `EnemyManager` shortens spawn time and adds/reweights enemies per `Balance.SPAWN_STEPS`.
- **Balance.** Tuning numbers live in `scripts/balance.gd`, not in scenes: `ENEMIES` (health, speed, acceleration, drop chance, loot by drop id), `DROP_SCENES`, spawn timing and `SPAWN_STEPS`, `WEAPONS` (damage, cooldown), and `UPGRADES` (name, description, max quantity, pool weight, per-level `percent`, `unlocked_by`, `ability_controller_scene`). Each enemy script has a `const ENEMY_ID` and calls `Balance.apply_enemy_stats(self, ENEMY_ID)` in `_ready()`, which overwrites its `HealthComponent`, `VelocityComponent` and `LootDropComponent`. Ability controllers read `Balance.WEAPONS` and start their `Timer` with the cooldown. Don't put these values back into `.tscn` overrides. Controllers read upgrade effects from `Balance.UPGRADES[id]["percent"]`, and `{percent}` in a description is filled from the same value, so card text and math can't drift. Never hardcode a number in a description. The player still uses scene values for health and speed.
- **Physics layers:** 1 Terrain, 2 Player, 3 Enemy, 4 EnemyCollision, 5 PlayerPickup.

## Adding things (checklists)

- **New upgrade:** add an entry to `Balance.UPGRADES` (unique id; `unlocked_by` if it depends on an ability; use `{percent}` in the description), and handle its id in the relevant controller's `_on_ability_upgrade_added`, reading `percent` from `Balance.UPGRADES`.
- **New ability:** controller scene + ability scene under `scenes/ability/`, a `Balance.WEAPONS` entry for its damage/cooldown, and a `Balance.UPGRADES` entry with `ability_controller_scene` set to the controller's path (see "New upgrade").
- **New enemy:** scene under `scenes/game_object/enemies/` with the standard components (node names `HealthComponent`, `VelocityComponent`, `LootDropComponent`), a `const ENEMY_ID` + `Balance.apply_enemy_stats` call in its script, an entry in `Balance.ENEMIES` and `Balance.SPAWN_STEPS`, and an `@export` + `enemy_scenes` entry in `enemy_manager.gd`. See "Known inconsistencies" below: hit flash and death animation only work for `Sprite2D` enemies so far.

## Known inconsistencies

Two styles of enemy visuals coexist. The direction is **`AnimatedSprite2D` for enemies going forward**; the rat is the legacy pattern.

- **Rat (`rat_enemy`), tutorial style:** a static `Sprite2D` animated by an `AnimationPlayer` (`walk`: position/rotation tweaks). Has `HitflashComponent` (white flash on damage) and `DeathComponent` (sprite spins up, shrinks and fades).
- **Bug (`bug_enemy`), animated style:** an `AnimatedSprite2D` with Kenney frames (`bug_1..3.png`). Hit flash and death animation do **not** work: `HitflashComponent.sprite` and `DeathComponent.sprite` are typed `Sprite2D`, so neither component is on the bug. A dead-pose sprite (bug lying down) exists but isn't wired up yet.
  - Outstanding: make damage flash and death work for `AnimatedSprite2D` (e.g. type the export as `CanvasItem`/`Node2D`, and have death use the dead-pose frame).
- **`DeathComponent` particle texture is hardcoded** to `rat_enemy.png` in `death_component.tscn`, so it's rat-specific until it reads the texture from its `sprite`.
- **Slug (`slug_enemy`), in progress:** an `AnimatedSprite2D` enemy started by duplicating the bug. Its movement visuals will differ: it should rotate to point at the player, rather than flipping `Visuals.scale.x` by movement direction like the rat and bug.
- `rat_enemy.gd` and `bug_enemy.gd` are currently identical; the slug's script will diverge (rotation).

## Code style

- Tabs for indentation. Two blank lines between functions.
- `snake_case` names; `class_name` in PascalCase for types referenced elsewhere.
- **Function naming:** functions used only inside their own script get a leading underscore (`_get_spawn_position`); functions called from other scripts or scenes have none (`damage`, `set_ability_upgrades`). Signal handlers are internal: `_on_<source>_<signal>`. A method one instance calls on another instance of the same class counts as shared (e.g. `AbilityUpgradeCard.play_discard`). When a function's usage changes, rename it and update every caller.
- `@onready var x = $Node` for child references; `@export` for cross-scene references.
- Frame-rate-independent smoothing uses `lerp(..., 1 - exp(-k * delta))`.
