# Astro Drift — Defold

Drifting-ship demo for the [Defold](https://defold.com/) engine. Lua-scripted entities (Defold "Game Objects") with an input-binding that maps keys to named actions.

## Open

1. Install the [Defold editor](https://defold.com/download/) (free, ~150 MB).
2. **File → Open From Disk…**, point at this `defold/` directory.
3. The editor will reimport assets on first open and compile the `.collection`/`.input_binding` to their binary `.collectionc` / `.input_bindingc` counterparts referenced from `game.project`.
4. Press **Build → Build and Launch** (or `Ctrl+B`).

## Files

- `game.project` — engine config: window size, bootstrap collection, render pipeline, input binding
- `main/main.collection` — root scene; spawns the player game object + a bullet factory
- `main/player.go` / `main/player.script` — ship game object + Lua script driving input, physics, screen wrap, and bullet spawning
- `main/bullet.go` / `main/bullet.script` — bullet game object with 1-second lifetime and screen wrap
- `input/game.input_binding` — keyboard bindings: `left`, `right`, `thrust`, `fire`, `quit`

## Controls

`W`/`↑` thrust · `A`/`D`/`←`/`→` rotate · `Space`/`J` fire · `Esc` quit

## Notes

This project is structured as a hand-authored Defold project — the `.collection`, `.go`, and `.input_binding` files are the text-format sources that the Defold editor compiles on open. They are valid Protobuf-text but the editor regenerates binary cache files on import, so first-launch may show a brief "importing" splash.
