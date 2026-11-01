# Breakout Clone

A small, complete Breakout clone for **Godot 4.5**, written in a single GDScript file with no external assets. It is a demo project for [godot-host-project](https://github.com/tyrese-r/godot-host-project), a service that takes a zipped Godot project, builds it for the Web and hosts it at its own URL.

Bounce the ball off your paddle and clear all 72 bricks. Where the ball lands on the paddle sets its angle, the ball speeds up as you break bricks, and the top row takes two hits.

## Controls

| Action | Keyboard | Mouse |
| --- | --- | --- |
| Move paddle | Left / Right arrows | Move the mouse |
| Start, launch ball, restart | Space or Enter | Left click |

## Gameplay

- 6 rows × 12 columns of coloured bricks. From the top row down they are worth 70, 50, 40, 30, 20 and 10 points.
- The top (red) row is armoured: it takes two hits and has a white outline until the first hit.
- You start with **3 lives** and lose one each time the ball falls past the paddle. The ball slows down a little after you lose a life.
- Hitting the middle of the paddle sends the ball straight up. Hitting nearer an edge sends it out at up to 60°.
- Every brick you hit makes the ball faster, up to a cap.
- Clear every brick to win. Each life you have left is worth a 100-point bonus. Your best score is kept until you close the game.

## Running locally

1. Install [Godot 4.5.x](https://godotengine.org/download) (standard build, no .NET needed).
2. Clone the repo:
   ```sh
   git clone https://github.com/tyrese-r/breakout-clone.git
   ```
3. Open Godot, choose **Import**, select `breakout-clone/project.godot` and press **F5**.

Or from the command line:

```sh
godot --path breakout-clone
```

### Requirements

- Godot **4.5.x** (tested with 4.5.1.stable)
- **Compatibility** renderer (`gl_compatibility`), so it runs in browsers through WebGL 2
- No GDExtensions, no threads and no platform-specific APIs, so it works with Godot's single-threaded Web export

## Project structure

```
breakout-clone/
├── project.godot        # Project settings: name, 1152x648 window, Compatibility renderer, main scene
├── main.tscn            # Main scene: one Node2D with main.gd attached
├── main.gd              # All the game code: bricks, paddle, ball, collisions, HUD and states
├── export_presets.cfg   # Web export preset (no threads) for command-line exports
├── icon.svg             # Project icon
├── LICENSE
└── README.md
```

`main.gd` builds everything in code and draws it with `_draw()`. It uses its own ball physics in `_physics_process` rather than physics bodies. The ball moves in small sub-steps so it can't pass through bricks at high speed. The game runs through these states: `TITLE → SERVE → PLAYING → WON / GAME_OVER`.

## Try it on Godot Host

This game was made to show off [godot-host-project](https://github.com/tyrese-r/godot-host-project). You upload a zipped Godot 4.5 project, it exports it for the Web and gives you a link where you can play it.

1. **Get the zip.** Download `breakout-clone.zip` from the [latest release](https://github.com/tyrese-r/breakout-clone/releases/latest). You can also zip this repo yourself, as long as you leave out `.godot/`:
   ```sh
   zip -r breakout-clone.zip breakout-clone -x 'breakout-clone/.godot/*' 'breakout-clone/.git/*'
   ```
2. **Run godot-host-project.** Follow its README. For example, from a clone of that repo:
   ```sh
   docker compose --profile worker up -d --build
   ```
3. **Upload the zip**, either through the upload page on your instance or with `curl`:
   ```sh
   curl -F title="Breakout Clone" -F file=@breakout-clone.zip http://localhost:8081/api/builds
   # => {"id": "..."}
   ```
   Change `http://localhost:8081` to your instance's address if it runs somewhere else, e.g. `https://your-godot-host.example`.
4. **Play.** When the build finishes, open `http://localhost:8081/<id>` using the `id` from the response.

## Credits

This project was developed with the assistance of Claude, an AI model by Anthropic (Anthropic, 2026). It is built with the Godot Engine (Godot Engine contributors, 2026).

## References

Anthropic (2026) *Claude Opus 5.5* [Large language model]. Available at: https://www.anthropic.com/claude (Accessed: 25 September 2026).

Godot Engine contributors (2026) *Godot Engine* (Version 4.5.1) [Computer program]. Available at: https://godotengine.org (Accessed: 25 September 2026).

## Licence

Released under the MIT Licence. See [LICENSE](LICENSE).
