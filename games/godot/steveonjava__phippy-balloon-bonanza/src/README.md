# Phippy Balloon Bonanza

A small Godot arcade-game example created during the Phippy AI Game Workshop.
Move Phippy across the island, catch as many balloon pods as possible, and
beat the 45-second clock.

## Run the game

1. Install [Godot 4.7](https://godotengine.org/download/).
2. Import `project.godot` in the Godot project manager.
3. Press **F6** or click **Run Project**.

From a terminal with Godot on your path, you can also run:

```bash
godot --path .
```

## Controls

| Action | Keys |
| --- | --- |
| Start | Space |
| Move | Left/Right arrows or A/D |
| Restart | R |

## Project layout

- `scenes/Main.tscn` is the entry scene.
- `scripts/main.gd` manages the game state, timer, scoring, and HUD.
- `scripts/player.gd` controls Phippy's movement and animation.
- `scripts/balloon.gd` controls falling pods, collisions, and pop animations.
- `assets/pixel/phippy-rescue/` contains the artwork used by the game.

## Credits and licenses

The game code is available under the MIT License in `LICENSE`.

The pixel art comes from the MIT-licensed
[PhippyRescue](https://github.com/Tingsters/PhippyRescue) project, imported
from commit `97d967673fc10621593334c3814ce993d2e50ea5`. Its original license and
copyright notice are preserved in `assets/licenses/PhippyRescue-MIT.txt`.

Phippy and related names and artwork may also be subject to the Linux
Foundation's trademark usage guidelines. This example is not sponsored or
endorsed by CNCF or the Linux Foundation.

