# Lua Vector Game

A simple 2D target-collection game built with [LÖVE](https://love2d.org/) that demonstrates vector math concepts such as translation, addition, and Euclidean distance.

## Gameplay

- You control a **green dot** (the player) on screen.
- **Red circles** (targets) spawn at random positions.
- Type a translation vector (e.g., `50 -20`) and press **Enter** to move the player by that amount.
- Collect targets by moving close enough to collide with them.
- Each collected target increases your score and spawns a new one.

## Concepts Demonstrated

- **Vector class via metatables** — custom `Vector` type with constructor, operator overloading (`__add`), and methods (`dist`).
- **Euclidean distance** — used for collision detection between the player and targets.
- **Vector addition** — player movement is applied by adding a translation vector to the current position.

## Prerequisites

- [LÖVE 11.x+](https://love2d.org/) (the Love2D game framework)

## Running the Game

```bash
love .
```

Run this command from the project root directory.

## Controls

| Key / Input | Action |
|---|---|
| Digits, spaces, `-` | Type a translation vector (e.g., `50 -20`) |
| Enter | Apply the vector and move the player |
| Backspace | Delete the last character of your input |

## Project Structure

```
├── main.lua   -- Game source (Vector class, game loop, input handling)
├── LICENSE    -- MIT License
└── README.md  -- This file
```

## License

This project is licensed under the [MIT License](LICENSE).
