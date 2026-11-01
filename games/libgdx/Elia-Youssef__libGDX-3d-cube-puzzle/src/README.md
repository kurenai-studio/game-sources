# 3D Cube Puzzle

A fast-paced spatial-reasoning puzzle built with libGDX. Two mismatched 3D puzzle pieces hang
suspended in space, each in a random, incorrect orientation. Rotate both pieces back into their
correct alignment to reassemble the complete cube before the one-minute timer runs out.

## Environment

- **Java 8** (`--release 8`)
- **libGDX 1.14.0**
- **lwjgl3** desktop backend
- Fixed **800x600** window (not resizable)

The two puzzle pieces are built from the provided `CubePuzzleFactory.java`. Every other visual
(the selection glow, the timer, and the win/lose text) is generated at runtime with `ModelBatch`
lighting, `ShapeRenderer`, and the default `BitmapFont`. No external art, textures, or audio
files are used.

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

To build the runnable fat JAR:

```
./gradlew lwjgl3:jar
```

The JAR is written to `lwjgl3/build/libs/CubePuzzle.jar` and can be launched directly with
`java -jar CubePuzzle.jar`.

To build both required submission files in one step:

```
./gradlew deliverables
```

This writes `3D-Cube-Puzzle.zip` and `CubePuzzle.jar` to `build/deliverables/`. The ZIP contains
the complete Gradle source project and wrapper, while excluding generated build output and local
QA captures.

## Controls

- **Tab**: switch which piece is selected (the upper piece is selected by default)
- **Arrow keys**: rotate the currently selected piece (90 degrees per press)
- **R**: restart at any time (during play, mid-animation, after a win, or after a loss) - resets
  the timer to 1:00 and randomizes both pieces' starting orientations

## Objective

Rotate both suspended pieces until each is back in its correct orientation at the same time. Once
both match, the pieces slide together and snap into the completed cube and "You Win" appears. If
the timer reaches zero first, the pieces stay separated and "You Lose" appears. Press R to try
again.

## License

This project is available under the [MIT License](LICENSE).
