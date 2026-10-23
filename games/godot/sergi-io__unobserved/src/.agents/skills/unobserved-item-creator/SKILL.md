---
name: unobserved-item-artifact-creator
description: Add new collectible items, upgrades, and active artifacts to Unobserved. Use when creating or changing item pickup scenes, artifact unlocks, artifact HUD entries, cooldowns, item effects, inventory/debug presentation, upgrade choices, or network item spawning.
---

# Unobserved Item And Artifact Creator

Use this skill when adding a new collectible item, upgrade, pickup, or active artifact to the game.

## Item vs Artifact

Unobserved uses items and artifacts differently. Decide which one you are building before editing.

- Item: a passive upgrade, consumable, XP box, or in-world pickup. Items usually use `ItemPickup`, can appear under `ItemField`, and apply their effect through `Ship.collect_item()`.
- Artifact: an unlockable active ability owned by the ship. Artifacts appear in the bottom-right Artifact Hud only when unlocked, activate from their HUD button or number shortcuts `1`, `2`, `3`, etc. based on HUD order, and always require a configurable cooldown plus visual cooldown state.

Artifacts are not automatically galaxy pickups. By default, do not add artifact spawn counts, do not spawn them from `ItemField._spawn_items()`, and do not set scene overrides such as `wormhole_dash_count = 1`. Only make an artifact collectible from the galaxy when the user explicitly asks for that.

## Start Here

Inspect the current implementation before editing:

- `scripts/item_pickup.gd` - pickup node behavior, display name, description, fallback icon loading, and collection handoff.
- `scripts/item_field.gd` - item scene preloads, upgrade catalog, random upgrade choices, world spawning, network item instantiation. Keep artifacts out of `_spawn_items()` unless explicitly requested.
- `scripts/ship.gd` - collection effects, inventory/artifact ownership, active artifact behavior, cooldown state, upgrade preview text, and network inventory restore behavior.
- `scripts/ui/item_presentation.gd` - inventory/debug names, icons, artifact HUD membership, and debug item list.
- `scripts/ui/galaxy_ui.gd` - Artifact Hud creation, artifact buttons, shortcut labels, disabled cooldown state, and cooldown label updates.
- `scripts/ui/artifact_cooldown_mask.gd` - radial black/white cooldown mask drawn over artifact buttons.
- `scripts/galaxy.gd` - artifact shortcut routing, HUD activation requests, and cooldown refresh.
- `scripts/galaxy_network_controller.gd` - multiplayer artifact activation and replicated ship tunables.
- `scenes/items/*.tscn` - one pickup scene per item kind.
- `textures/items/*` - item icons and pickup sprites.
- `textures/artifacts/*` - artifact HUD icons.

Also load `godot-gdscript-patterns` if the new item or artifact needs new GDScript behavior beyond simple data registration.

## Existing Item Shape

Items are Godot `Node2D` scenes under `scenes/items/`. Each scene usually has:

```text
Root Node2D
  script = res://scripts/item_pickup.gd
  item_kind = &"snake_case_kind"
  item_level = 1
  Sprite2D
    texture = res://textures/items/<asset>.png
    scale = Vector2(...)
```

`ItemPickup` detects pickup overlap, then calls:

```gdscript
ship.collect_item(item_kind, item_level, repair_amount, global_position)
```

The item kind is the stable ID. Use lower `snake_case` `StringName` values and keep them consistent everywhere.

## Existing Artifact Shape

Artifacts use the same stable `StringName` inventory keys as items, but their gameplay is active instead of passive. They generally have:

- An item kind constant in `scripts/item_pickup.gd`, for example `ITEM_WORMHOLE_DASH`.
- An icon under `textures/artifacts/`.
- An entry in `scripts/ui/item_presentation.gd`:
  - `ITEM_ICON_TEXTURES` for the icon.
  - `ARTIFACT_ITEM_KINDS` so the Artifact Hud shows it.
  - `DEBUG_ITEM_KINDS` only if it should be grantable from debug UI.
- Ship state in `scripts/ship.gd`:
  - an ownership level, for example `_wormhole_dash_level`.
  - an exported cooldown, for example `wormhole_dash_cooldown_seconds`.
  - `collect_item()` unlock logic.
  - `get_upgrade_preview()` text that includes the active behavior and cooldown.
  - `has_artifact()`, `_get_artifact_level()`, `activate_artifact()`, and behavior helpers.
  - `_get_artifact_cooldown_duration()` and `get_artifact_cooldown_states()` support.
- Optional catalog scene under `scenes/items/` if the artifact can be offered as a level-up/debug unlock. This scene is an unlock/catalog entry, not proof that it should spawn naturally in the galaxy.

## Add A New Item

1. Define the item contract:
   - `item_kind`: lower `snake_case`, for example `&"tractor_beam"`.
   - Display name and short description.
   - Pickup scene path: `res://scenes/items/<item_kind>.tscn`.
   - Texture path: `res://textures/items/<item_kind>.png`.
   - Collection behavior: stat increase, timed effect, consumable heal, XP, or inventory-only item.

2. Add the visual asset:
   - Put the source texture under `textures/items/`.
   - Do not edit `.import` files or `.godot/` cache files manually.
   - If Godot generates import metadata during validation, review the diff and keep only intentional project assets.

3. Create the pickup scene:
   - Prefer Godot MCP editor operations when available.
   - A minimal text scene is acceptable when it follows the existing simple item scene pattern exactly.
   - Use a PascalCase root node name and a `Sprite2D` child.
   - Keep scene filenames lowercase and descriptive.

4. Register the item in `scripts/item_pickup.gd`:
   - Add a `const ITEM_<NAME>: StringName = &"<item_kind>"`.
   - Add match branches in `get_display_name()` and `get_display_description()`.
   - If the scene intentionally omits a texture resource, add a typed texture path/cache/load fallback similar to shield, vacuum, and radar.

5. Register spawning/catalog behavior in `scripts/item_field.gd`:
   - Add a `PackedScene` preload constant.
   - Include upgrade items in `get_upgrade_catalog()`.
   - Add the item to `get_scene_for_item_kind()`.
   - Only add it to `_spawn_items()` when it should appear naturally in the world at startup.

6. Implement collection behavior in `scripts/ship.gd`:
   - Add state fields only when the item needs persistent behavior beyond generic inventory count.
   - Add a branch in `collect_item()`.
   - Add a branch in `get_upgrade_preview()` for level-up options.
   - Update `apply_network_inventory()` and `_sync_inventory_from_loadout()` when the state must survive multiplayer snapshots.
   - Prefer helper methods for effect calculations if the item changes gameplay formulas used elsewhere.

7. Update UI/debug presentation in `scripts/ui/item_presentation.gd`:
   - Add the icon preload to `ITEM_ICON_TEXTURES`.
   - Add the item to `DEBUG_ITEM_KINDS` if it should be grantable from the debug item buttons.
   - Add a display-name branch in `format_inventory_item_name()`.
   - Add special label formatting only when a normal count label is misleading, such as timers.

8. Check multiplayer surfaces:
   - Server and clients use `ItemField.get_scene_for_item_kind()` and `Ship.collect_item()`.
   - If the item changes replicated player state, update snapshot creation/application in `scripts/galaxy_network_controller.gd`.
   - If the item is only an inventory count or uses existing ship state paths, no network-specific code may be needed.

## Add A New Artifact

1. Define the artifact contract:
   - `artifact_kind`: lower `snake_case`, for example `&"phase_blink"`.
   - Display name and active behavior.
   - Icon path under `res://textures/artifacts/<artifact_kind>.png`.
   - Cooldown export name, for example `phase_blink_cooldown_seconds`.
   - Unlock source: level-up choice, debug grant, scripted reward, or galaxy pickup. Default to not a galaxy pickup.
   - Network needs: note any tunable values or replicated state the server and clients must share.

2. Add the visual asset:
   - Put artifact HUD icons under `textures/artifacts/`.
   - Do not edit `.import` files or `.godot/` cache files manually.
   - If Godot generates import metadata during validation, review the diff and keep only intentional project assets.

3. Add an optional unlock/catalog scene:
   - Use `scenes/items/<artifact_kind>.tscn` only if the artifact needs to appear as a level-up option, debug grant, or network-created unlock object.
   - Use `ItemPickup` with `item_kind = &"<artifact_kind>"`.
   - Keep the scene out of natural world spawning unless explicitly requested.

4. Register artifact presentation in `scripts/ui/item_presentation.gd`:
   - Add the icon preload to `ITEM_ICON_TEXTURES`.
   - Add the kind to `ARTIFACT_ITEM_KINDS`; this is what lets the Artifact Hud show it after unlock.
   - Add it to `DEBUG_ITEM_KINDS` only when debug granting is useful.
   - Add a display-name branch in `format_inventory_item_name()`.

5. Register catalog behavior in `scripts/item_field.gd` when needed:
   - Add a `PackedScene` preload constant for the optional unlock/catalog scene.
   - Include it in `get_upgrade_catalog()` only when level-up choices should offer it.
   - Add it to `get_scene_for_item_kind()` so debug/network item creation can resolve it.
   - Do not add an artifact count export.
   - Do not call `_spawn_item_group()` for the artifact in `_spawn_items()` unless the user explicitly says it can be picked up from the galaxy.

6. Implement artifact ownership and activation in `scripts/ship.gd`:
   - Add a private level field, for example `_phase_blink_level`.
   - Add an exported cooldown:

```gdscript
@export_range(0.0, 120.0, 0.1) var phase_blink_cooldown_seconds: float = 4.0
```

   - In `collect_item()`, unlock the artifact and set the inventory level.
   - In `get_upgrade_preview()`, describe the active behavior and include the cooldown.
   - In `apply_network_inventory()` and loadout sync paths, restore ownership and clear cooldown state if the artifact is no longer owned.
   - In `_get_artifact_level()`, return the artifact level.
   - In `_get_artifact_cooldown_duration()`, return the exported cooldown.
   - In `activate_artifact()`, check ownership and cooldown before activating; start cooldown only when the behavior succeeds.
   - Keep behavior helpers small and named by artifact, for example `_activate_phase_blink()`.

7. Keep cooldown HUD behavior working:
   - `Ship.get_artifact_cooldown_states()` must include every owned artifact with `time_left` and `duration`.
   - `Galaxy._refresh_artifact_cooldowns_ui()` passes those states into `GalaxyUi.refresh_artifact_cooldowns()`.
   - `GalaxyUi` disables artifact buttons while cooling down, shows `CooldownMask`, and displays the remaining seconds.
   - Do not bypass this flow with artifact-specific HUD code unless the artifact needs genuinely custom UI.

8. Wire activation and shortcuts:
   - Existing Artifact Hud buttons emit `artifact_activation_requested`.
   - Existing number shortcuts use `GalaxyUi.get_artifact_kind_at_shortcut()`, so order comes from `ARTIFACT_ITEM_KINDS` and unlocked inventory order.
   - Add custom input only if the user asks for a separate shortcut.

9. Check multiplayer surfaces:
   - Add tunable artifact properties, such as cooldown or distance, to `NETWORK_SHIP_TUNABLE_PROPERTIES` when clients need matching behavior.
   - Server-side activation should still call `Ship.activate_artifact()`.
   - If activation changes shared game state beyond the ship, update snapshots or RPCs deliberately.

## Artifact Reference: Wormhole Dash

Use Wormhole Dash as the current reference implementation.

- Kind: `&"wormhole_dash"`.
- Icon: `res://textures/artifacts/wormhole-dash.png`.
- Not a galaxy pickup: it is not spawned by `ItemField._spawn_items()` and has no spawn count override in `scenes/galaxy.tscn`.
- HUD: shown through `ARTIFACT_ITEM_KINDS` after the ship owns it.
- Activation: jumps the ship forward in the direction it is facing, clamps to galaxy bounds, then sets a continuation target two dash distances beyond the landing point so the ship keeps moving and decelerates naturally.
- Cooldown: configured by `wormhole_dash_cooldown_seconds` and shown through the shared Artifact Hud cooldown mask.

## Keep The Change Scoped

- Do not rewrite existing scenes wholesale.
- Do not rename existing item kinds.
- Do not change generated UIDs unless creating a new resource through Godot requires it.
- Keep pickup scene scripts shared through `ItemPickup`; create a custom item script only when the pickup itself needs unique in-world behavior before collection.
- If adding a consumable that should not stay in inventory, return early from `collect_item()` after applying the effect, following `repairset` and `xpbox`.
- For artifacts, default to unlock/catalog behavior instead of world pickup behavior.
- Every artifact in the Artifact Hud must have a configurable cooldown.
- Every artifact cooldown must use the shared cooldown state flow so buttons disable and show the radial mask/countdown.

## Validation

Run the narrowest useful checks:

```sh
godot --headless --path . --quit
make typecheck
```

If `godot` is not on `PATH`, use the local Godot 4.6 binary configured for this project. Run Godot outside the sandbox. For visual or interaction changes, run the project from the editor and verify pickup, inventory UI, level-up options, debug grant buttons, and multiplayer behavior when touched.

For artifact changes, also add or run focused checks for:

- artifact unlock causes the Artifact Hud button to appear.
- button click and numeric shortcut both activate the artifact.
- cooldown blocks immediate reactivation.
- cooldown mask and remaining seconds disappear after cooldown.
- galaxy pickup spawning stays disabled when the artifact should not be picked up from the galaxy.
