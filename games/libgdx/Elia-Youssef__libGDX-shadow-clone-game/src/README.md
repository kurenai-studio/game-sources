# Shadow Clone

A 2D puzzle-platformer built from scratch with **libGDX 1.14.1** (Java 21, lwjgl3 desktop backend).
The whole game is built around one mechanic: **your actions are recorded for a fixed 5 seconds and
then replayed by a holographic clone.** You solve a facility of increasingly complex puzzles by
becoming your own team - clones hold switches, form bridges, ride elevators, sacrifice themselves to
lasers, distract security, and coordinate to stabilize the reactor core.

## Run it

Requires a JDK (17+; developed on JDK 21). From this `project/` folder:

```
./gradlew lwjgl3:run          # macOS / Linux
gradlew.bat lwjgl3:run        # Windows
```

The first build downloads Gradle + the libGDX dependencies from Maven Central; after that it runs
offline. A 1280x720 window opens on the Main Menu. The game is **asset-free** - every graphic is
drawn with `ShapeRenderer` primitives and the built-in `BitmapFont`, so there is nothing under
`assets/` to ship.

## Controls

| Action | Keys |
|--------|------|
| Move left / right | Left / Right arrows (or A / D) |
| Jump | Space (or W / Up) |
| Use / interact (terminals, redirect) | E |
| Reset the current recording | R |
| Restart the level (full reset) | Backspace |
| Back to the Main Menu | Esc |

Menu and Victory buttons are clickable; Enter also starts the run.

A clone is deployed automatically every 5 seconds and repeats exactly what you did during that
window. Plan your 5-second takes so each clone ends up where you need it (on a switch, on a plate,
crossing a beam).

## Architecture

Two Gradle modules, package root `com.micro1.shadowclone` (launcher in `...lwjgl3`).

- **The simulation runs on a fixed 60 Hz timestep.** `PlayScreen` accumulates real frame time and
  runs whole `DT = 1/60 s` steps, so a replay is frame-for-frame identical to the recording.
- **Input, not position, is recorded.** `Recorder` captures the live player's `InputFrame`
  (`left, right, jumpPressed, interactPressed`) each step over a rolling 5 s window. When the window
  closes it emits a `Recording` (the frames + the player's pose when the window opened) and a
  `Clone` is deployed.
- **One physics routine for everyone.** `Physics.step(body, frame, level, dt)` moves the player
  (live input) and every clone (recorded input) identically. Because a clone is a full physics body,
  a conveyor pushes it, an elevator carries it, and gravity + AABB collision apply during replay.
  This is why the clone "re-experiences" moving environments while repeating its recorded intent.
- **One-shot then hold.** A clone replays its take once, then feeds neutral input (stands still) but
  remains a physics body - so it keeps holding a switch it walked onto, yet is still carried by a
  conveyor it ends up on.
- **Data-driven levels.** One `PlayScreen` drives all 12 levels. `Levels.build(i)` populates a
  `Level` with typed entity lists (`Platform` with kinds SOLID/CONVEYOR/BRIDGE/ELEVATOR/MOVING,
  `Switch`, `Door`, `Laser`, `SecurityCamera`, `Core`). Rebuilding a level from the factory is a
  clean, complete reset.

Key classes: `ShadowCloneGame` (shared batch/shapes/font + screen flow), `Recorder`/`Recording`/
`Clone` (record + replay), `Physics`/`Body` (movement + collision), `Level`/`Levels` (level model +
builders), `Hazards` (laser/pit resolution), `WorldRenderer` + `Hud` (rendering), `MenuScreen` /
`PlayScreen` / `VictoryScreen`.

## Clone-recording logic (in detail)

1. A rolling 5 s window is always active while you play. Each fixed step the live player's inputs are
   appended to the current take and the countdown advances (shown as `REC 05:00 -> 00:00` with a
   segmented bar).
2. When the window closes, the take (plus the pose it started from) becomes a `Recording`, a `Clone`
   is deployed at that start pose, and a fresh window opens from your current position. Pressing **R**
   discards the in-progress take and restarts the window.
3. Each step, a clone consumes the next recorded `InputFrame` and is advanced by the same
   `Physics.step` as the player. Jump and interact are stored as edge events on the exact step they
   occurred, so their timing replays precisely. After the last frame the clone holds (neutral input,
   still a physics body).
4. Determinism: there is no randomness in the simulation, and everything advances only inside a fixed
   step, so a clone reproduces the recorded path exactly under the same environment. Timed lasers use
   periods that divide the 5 s window, so clones stay laser-aligned on replay.

## Scenes

Main Menu -> 12 levels (Clone Tutorial, Dual Switch, Clone Bridge, Elevator, Laser Corridor, Triple
Clone, Conveyor Room, Timing Chamber, Security Facility, Master Puzzle, Clone Core, Escape Sequence)
-> Victory. Each level shows a numbered badge, description, live recording timer + clone count, and
an objective. The exit opens only while its required switches are held, so a clone is genuinely
required (you cannot hold a distant switch and stand at the exit at once).

## Assumptions and limitations

- **Recording length is fixed at 5 seconds** and clones deploy automatically at the end of each
  window (matching the reference "every 5 seconds" framing) rather than via a manual record toggle.
- **Clones are one-shot-then-hold**, not looping, which keeps switch-holding puzzles stable while
  still letting moving environments carry a finished clone.
- **Lasers block the player** (a push-out) rather than killing on contact, so accidental contact
  never wipes a staged attempt; they still destroy clones (the Laser Corridor sacrifice). Death (and
  the deaths counter) comes from falling into a pit or letting the Escape countdown expire; either
  fully restarts the level.
- **Active clones are capped** (oldest dropped past the cap) to bound rendering; puzzles never need
  more than three at once.
- **Asset-free by design**: primitives + the built-in font, no external art/audio. The look follows
  the reference pack's dark-facility / neon-cyan intent rather than reproducing the pixel art.
- Desktop (lwjgl3) only; Android/iOS/HTML backends are out of scope for this vertical slice.

## License

This project is available under the [MIT License](LICENSE).
