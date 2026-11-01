# Circuit Salvage

A small top-down arcade game built with libGDX. You are a repair bot on an 8x8 salvage grid:
collect 3 batteries while avoiding 2 moving spark hazards, then reach the exit once it powers on.

## Environment

- **Java 17**
- **libGDX 1.14.2**
- **lwjgl3** desktop backend
- Fixed **640x480** window (not resizable)

Every visible element (grid, player, batteries, sparks, exit, and HUD text) is generated at
runtime from `ShapeRenderer` primitives and the default `BitmapFont`. No external art, sprite
sheets, texture packs, custom fonts, or audio files are used.

## Build and run

From the project root:

```
./gradlew lwjgl3:run
```

On Windows:

```
gradlew.bat lwjgl3:run
```

To run the headless logic tests:

```
./gradlew core:test
```

## Controls

- **WASD** or **Arrow keys**: move (four cardinal directions only, no diagonal movement)
- **R**: restart the round at any time (during play, after a win, or after a loss)

## Objective

Collect all three batteries (the HUD shows `Batteries: n/3`). Once all three are collected the
exit at the top-right of the grid unlocks (`Exit: OPEN`). Reach the exit tile to win. Touching
either moving spark ends the round immediately. Press R to try again.

## License

This project is available under the [MIT License](LICENSE).
