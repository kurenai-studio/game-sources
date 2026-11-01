# Validation Report

Validated on 2026-08-23 with **Godot 4.7.stable.official** (`5b4e0cb0f`).

## Engine checks

- Project imported successfully.
- Main scene launched successfully.
- Gameplay scene completed a 900-frame headless survival run without project errors.
- All 20 GDScript files parsed.
- All 17 `.tscn` scenes resolved their script and scene references.
- `project.godot` loaded with the configured main scene and seven required actions.
- The Windows Desktop preset completed an `--export-pack` resource export successfully.

## Automated smoke checks

- All required InputMap actions exist.
- Main menu, game, actors, pickups, HUD, and modal scenes load as `PackedScene` resources.
- Game creates Player, HUD, and WaveManager.
- Shooting creates a player projectile.
- Enemy death increments kills and score.
- Player damage reduces health.
- Pause displays the pause menu and resume restores play.
- Upgrade selection pauses play, applies a choice, and resumes.
- Boss ranged pattern creates enemy projectiles.
- Boss death removes its health bar.
- Rapid Fire pickup applies its temporary effect.
- Player death enters the game-over state.
- Restart reloads the gameplay scene.

The validation host emitted a Windows root-certificate-store warning because its sandbox cannot access the machine certificate store. Shadow Survivors does not use networking or certificates, and the warning is unrelated to project resources or gameplay.
