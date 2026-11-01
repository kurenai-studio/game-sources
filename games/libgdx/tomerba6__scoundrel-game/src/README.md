# Scoundrel

[![CI](https://github.com/tomerba6/scoundrel-game/actions/workflows/ci.yml/badge.svg)](https://github.com/tomerba6/scoundrel-game/actions/workflows/ci.yml)
[![engine coverage](.github/badges/coverage.svg)](#testing)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Java 21](https://img.shields.io/badge/Java-21-e76f00.svg)](https://openjdk.org/projects/jdk/21/)
[![libGDX](https://img.shields.io/badge/libGDX-1.14-c0392b.svg)](https://libgdx.com/)

A desktop implementation of **Scoundrel**, a single-player roguelike card game — hand-drawn
pixel art over a rules engine that is pure, headless and driven entirely by tests.

Scoundrel is a solitaire dungeon crawl played with a trimmed deck of 44 cards. You descend
through a dungeon of face-up cards, fighting monsters, swapping weapons and drinking potions,
trying to reach the bottom of the deck alive. It is quick, tense, and entirely about managing
risk with the hand the shuffle deals you.

![The board](docs/images/board.png)

## What's new in 2.2

**Leave a run with ESC.** Until now a run ended only by finishing it or closing the window. ESC
now asks **ABANDON THIS RUN?** first, and an abandoned run is recorded nowhere: no ledger entry
and no trophies. KEEP PLAYING, or a second ESC, carries on.

## What's new in 2.1

**Sound.** Every action has its sound, landing on its animation's beat; a slow, brooding score
runs under the menus and the descent, with cues for getting out and for dying; and the torch
crackles on every screen. MUSIC and SOUND levels sit on the title, and **M** mutes everything
from anywhere. Every sound is synthesized in Python, signed off by ear — see
[`docs/audio.md`](docs/audio.md). Also fixed: an unlocked trophy's description no longer runs off
the end-of-run panel.

## What's new in 2.0

Release 1 played the whole game in flat coloured tiles. Release 2 is the same engine wearing
drawn art, and it took every screen with it.

- **31 hand-drawn objects** — 13 creatures, 9 weapons, 9 potions — drawn as **44 base sprites**
  at 64×64, since every creature exists in both corrupted suits, plus **130 idle frames**. All
  packed into an atlas at build time. Every pixel sits on a locked 80-colour ramp system; the
  struck and outlined frames are generated in Java at load rather than shipped.
- **Every screen redrawn** on the same pixel kit — title, mode select, ledger, trophies, the
  run-end panel and the tutorial overlay. **Scene2D is gone from the project entirely**, and
  with it both vector typefaces: Silkscreen is now the only face in the game.
- **A fixed 1280×720 design space**, rendered once to an offscreen surface and scaled to the
  window in one step, on a viewport that snaps to half-scales so pixel art never lands on a
  fractional grid.
- **Motion on a frame grid.** Nothing tweens: effects hold at 12 fps and idles at 6, floored in
  one place. The death cinematic is the slowest thing in the game on purpose — every other
  effect was cut to pay for it.

## Features

- **The complete ruleset** — room dealing, avoiding, armed and bare-handed combat, weapon
  degradation, the one-potion-per-turn cap, and both scoring branches including the
  cap-plus-final-potion edge case.
- **Three difficulty modes** — Standard, Relentless and Frail, built as alternate rulesets rather
  than branches in the engine.
- **Guided tutorial** — a scripted 22-step run that teaches every rule, offered once on first
  launch and replayable afterwards.
- **Persistent progression** — high scores and lifetime statistics across every finished run,
  with ten achievements derived from the engine's event stream. The ledger ranks all modes in
  one table and tags each row with the mode it was run in; "new best" is judged per mode, so a
  first Frail run earns it without competing against Standard scores.
- **Drawn presentation** — sprites that breathe on a shared clock, cards that deal in and sweep
  away, per-card resolve effects, a death cinematic, and a procedural torchlit backdrop with
  live flicker and drifting embers.
- **Sound** — crunchy lo-fi effects, one per moment, each
  landing on its animation's beat and weighted by the card's value; a brooding run track and a
  stripped-back menu track that crossfade as the screens cut; win and death cues, the music
  dying with the torch; a crackling torch on every screen. MUSIC and SOUND levels on the title,
  M to mute from anywhere. Every sound is synthesized in Python — see [`docs/audio.md`](docs/audio.md).
- **Ships as a real application** — self-contained Windows and macOS builds that need no Java
  installed, borderless fullscreen with an F11 toggle, and crash reports written to disk.

## Play it

Download a self-contained build from the [latest release](https://github.com/tomerba6/scoundrel-game/releases/latest)
— each bundles its own trimmed JDK, so **no Java installation is required**.

| Platform | File |
|---|---|
| Windows (x64) | `Scoundrel-winX64.zip` |
| macOS (Apple Silicon) | `Scoundrel-macM1.zip` |

The builds are unsigned, so the first launch shows a warning: on Windows choose
**More info → Run anyway**; on macOS right-click the app and choose **Open**.

Or build from source — the Gradle wrapper is included, so you only need a JDK 21+:

```sh
./gradlew lwjgl3:run      # play
./gradlew core:test       # run the tests
./gradlew core:check      # tests + the coverage gate
```

On Windows use `gradlew.bat`. If the game ever crashes, the uncaught error is appended to
`~/.scoundrel/crash.log` (`%USERPROFILE%\.scoundrel\crash.log`) — useful to attach to a report.

## The game

The deck is 44 cards: the 26 clubs and spades are **monsters**, diamonds 2–10 are **weapons**,
hearts 2–10 are **potions**. You start at **20 health**, which is also the cap.

- **Rooms.** Cards are dealt four at a time. Resolve three of them; the fourth carries into the
  next room.
- **Avoiding.** Instead of fighting you may scoop the whole room to the bottom of the dungeon —
  but never two rooms in a row.
- **Combat.** Bare-handed you take the monster's full value. With a weapon you take
  `monster − weapon`, floored at zero.
- **Weapon degradation.** Once a weapon kills, it may only be used on monsters *strictly weaker*
  than its last kill. It stays equipped for weaker foes; anything equal or tougher must be fought
  bare-handed. This is the rule the whole game turns on.
- **Scoring.** Clear the dungeon and you score the health you kept. Die and you score a negative
  number: your health minus every monster still face-down in the dungeon — so dying early, with
  the deck still full, is far worse than dying on the last room.

Three difficulty modes ship: **Standard**, **Relentless** (avoiding is forbidden) and **Frail**
(14 health, and healing capped there).

<table>
  <tr>
    <td width="50%"><img src="docs/images/tutorial.png" alt="The guided tutorial"></td>
    <td width="50%"><img src="docs/images/modes.png" alt="Mode select"></td>
  </tr>
  <tr>
    <td align="center"><em>A scripted run that teaches every rule, corner ticks on the card it means</em></td>
    <td align="center"><em>Three rulesets, no engine changes</em></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/images/records.png" alt="The Ledger"></td>
    <td width="50%"><img src="docs/images/trophies.png" alt="Trophies"></td>
  </tr>
  <tr>
    <td align="center"><em>Persisted high scores across every mode, each run tagged with its mode, beside lifetime totals</em></td>
    <td align="center"><em>Achievements derived from the engine's event stream</em></td>
  </tr>
  <tr>
    <td colspan="2"><img src="docs/images/title.png" alt="Title screen"></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><em>The Debt, idling at ×3 — the only sprite on any menu</em></td>
  </tr>
</table>

## Tech stack

| | |
|---|---|
| **Language** | Java 21 (records, sealed types, pattern matching for `switch`) |
| **Framework** | [libGDX](https://libgdx.com/) 1.14 with the LWJGL3 desktop backend |
| **UI** | Immediate-mode pixel art over a `Pixmap`-generated backdrop; hand-drawn sprites packed into an atlas at build time. No Scene2D, no layout engine — the art is specified as pixels at fixed positions |
| **Build** | Gradle 9 multi-module, wrapper committed |
| **Testing** | JUnit 5, JaCoCo coverage gate |
| **CI/CD** | GitHub Actions — checks on every PR, tag-triggered release builds |
| **Packaging** | [construo](https://github.com/fourlastor-alexandria/construo) — self-contained archives with a trimmed JDK per platform |
| **Fonts** | Silkscreen, rasterised at runtime via FreeType — 1-bit, unhinted, nearest-filtered, at whole pixel sizes |
| **Audio** | Synthesized offline in Python (numpy, soundfile) into WAV effects and OGG streams, played through libGDX's OpenAL backend |

No third-party dependency does any game logic; the rules are entirely first-party code.

## Architecture

The problem worth solving here was keeping a *game* testable. Games tend to grow rules inside
render loops, where verifying them needs a GPU and a human watching — so the rules stop being
tested, and edge cases like weapon degradation quietly rot. The whole structure below exists to
avoid that: push every rule into code that a headless test can drive, and leave the graphics layer
with nothing to get wrong except drawing.

The organising constraint is a hard boundary: **the rules engine is pure Java with no libGDX
imports at all.** Not "mostly pure" — `model` and `rules` contain zero `com.badlogic.gdx.*`
references, so the entire game can be played to completion in a unit test with no window, no GL
context and no render loop. Everything else follows from that.

```
core/
  model/         cards, deck, game state — plain records, no behaviour beyond invariants
  rules/         moves, resolution, scoring — pure functions over state
  screens/       immediate-mode views (libGDX-bound) — draw state, translate input into moves
  runs/          run recording, high scores, lifetime stats  ─┐ pure, and observe the
  achievements/  achievement definitions and evaluation       │ engine from outside;
  tutorial/      the scripted first run and its gating        ├─ model/rules never
  audio/         what each moment sounds like, the music      │ import any of them
                 director, the volume                         ─┘
lwjgl3/          desktop launcher, ~300 lines, no game logic
```

Four decisions carry most of the weight:

**Moves are functions of state.** `engine.apply(state, move)` returns a new state *and the events
that occurred* — monster defeated, potion wasted, weapon degraded, room avoided, game won. Nothing
mutates in place, so any position is reproducible and testable in isolation.

**Features observe the event stream from outside.** Achievements, statistics and high scores are
built entirely on those events. The `core` module has no idea they exist and never imports them,
which is why adding achievements required no engine changes at all.

**Rules live in an injected `Ruleset`.** Starting health, room size, cards resolved per turn, the
health cap, potions per turn, avoid rules, the scoring strategy and the deck are all configuration.
The three difficulty modes are *factory methods*, not new code paths — Relentless and Frail added
zero branches to the turn loop.

**Cards are data.** A card references a definition with an effect that applies itself to the state.
Resolving dispatches to that effect rather than switching on suit, so a new card type is a new
definition, not a new `case` in the engine.

The UI layer only draws state and turns input into moves. Where a screen grew logic that could be
tested — text formatting, hit regions, frame timelines, which clock a card is on — it was extracted
into a small pure class (`RoomMotion`, `CardHitRegions`, `ClockText`, `FeedText`, `Labels`,
`ResolveEffect`, `TorchFlicker`, `Embers`, `Frames`, `ButtonRow`) with a characterization test
written *before* the move, leaving the screens as thin views. Where a helper needs a font, the
measuring is passed in as a function so the arithmetic stays headless.

The five navigable screens share one `PixelScreen` base whose `render` is **final**. That is not
tidiness: activating a menu target navigates, navigating disposes the screen, and drawing one more
frame afterwards reads freed native memory and kills the JVM rather than throwing. The guard sits
above a `drawContent` a subclass cannot reach until the check has passed, so the mistake stopped
being expressible.

Full design notes, including the locked edge-case decisions and Mermaid diagrams, are in
[`docs/design.md`](docs/design.md); the UI layer is documented in [`docs/ui.md`](docs/ui.md).

## Testing

762 test methods — 790 runs, since one of them is parameterised over the 29 sound-effect files — written
test-first for all pure logic. `./gradlew core:check` runs them and enforces a JaCoCo gate of
**90% line / 75% branch on every pure package** — the build fails below it.

> Every figure in this section is a measurement, not a claim, and the branch moves fast enough that
> they go stale. Re-derive rather than repeat: the method count is
> `grep -rhoE "@(Test|ParameterizedTest)\b" core/src/test/java --include=*.java | wc -l` (a bare
> `"@Test"` misses the parameterised method, and the count here ran one short from 2.1.0 to 2.2.0), and
> the runs are the `tests` totals in `core/build/test-results/test/`. The ratios come from
> `core/build/reports/jacoco/test/jacocoTestReport.xml`, which `./gradlew core:cleanTest core:test`
> refreshes (a plain `core:test` on an unchanged tree is skipped, leaving the old report).
>
> **Every percentage here is LINE coverage**, because that is what the gate enforces
> (`counter = 'LINE'`). Neither report states it: the XML holds raw counts
> (`<counter type="LINE" missed="2548" covered="877"/>`) and the HTML draws percentage bars only
> for instructions and branches, showing lines as a bare *missed / total*. So every line figure
> here is that division, and you can check it off the HTML yourself — for `screens`,
> `(3,425 − 2,548) / 3,425 = 25.6%`.
>
> Which also means the HTML's leading `Cov.` column is **instructions**, not lines. Three
> counters, three answers, and for `screens` today they are 29.1% instructions, 33.4% branches
> and 25.6% lines.

| Package | Line | Branch |
|---|---|---|
| `model` | 100.0% | 100.0% |
| `rules` | 99.1% | 93.1% |
| `runs` | 98.7% | 96.3% |
| `achievements` | 98.3% | 97.5% |
| `tutorial` | 97.5% | 86.4% |
| `audio` | 100.0% | 99.4% |

`screens` is deliberately **excluded** from the gate. It is GL-bound — it needs a window, a GPU and
real pixels — so it is verified by driving the actual game and screenshotting it instead. Gating it
would enforce a meaningless number and reward writing tests that assert nothing. The root package
is excluded too, for a narrower reason: gating is per package, and `ScoundrelGame` (GL-bound, 0 of
103 lines) shares it with the pure `CrashLog`, `Progress` and `LaunchSwitch` (28 of 29 lines,
96.6%), so the package reads 21.2%. The badge above therefore reports coverage of the six *gated*
packages, not the whole repository, which is the figure the build actually holds itself to —
`CoverageGateTest` fails if the badge's list of packages and the gate's ever disagree.

That said, the number is not meaningless as a *progress* signal, because the pure helpers extracted
out of the GL classes stay in the same package. `screens` splits cleanly in two:

| Inside `screens` | Classes | Source lines | Executable lines | Line coverage |
|---|---|---|---|---|
| pure helpers, no libGDX import (`PressGesture`, `LedgerRow`, `TextWrap`, `ScreenArt`, `Frames`, `Beats`, …) | 46 | 6,011 | 898 | 97.0% |
| GL-bound (`GameScreen`, `BoardView`, `PixelScreen`, `Theme`, `SoundBank`, the screens themselves) | 21 | 6,594 | 2,527 | 0.2% |

Two line counts because they tell different stories and only one of them is JaCoCo's. **Executable
lines** are what coverage is computed over, and they make the package read 25.6% overall. **Source
lines** are what `wc -l` gives you, and by that measure the pure half is 48% of the package rather
than 26% — the helpers are comment-heavy by design, so they carry far fewer executable lines than
their size suggests.

Either way the number rises by *extraction* rather than by new tests against rendering: **46 of
the 67 classes now have no libGDX import at all**, which is the reading that matters. It says how
much of the UI layer has stopped being untestable.

The engine's determinism is used deliberately: the tutorial's scripted run, for instance, is proven
by playing every one of its moves through the real engine in a test and asserting the narration's
promises against the actual scoring strategy — so the tutorial cannot silently start lying about
the rules.

## Development

```sh
./gradlew core:test        # 790 test runs, headless, ~2s of execution
./gradlew core:check       # tests + the JaCoCo gate + Javadoc (doclint as errors); HTML report at
                           #   core/build/reports/jacoco/test/html/
./gradlew lwjgl3:run       # play the current working tree
./gradlew lwjgl3:packageWinX64   # build a self-contained archive

# the audio (Python 3 + audio-source/requirements.txt)
python audio-source/render.py    # re-synthesize everything into assets/audio/
python audio-source/check.py     # measure it: levels, seams, peaks; non-zero on a failure
```

`SCOUNDREL_AUDIO_LOG=1 ./gradlew lwjgl3:run` logs every sound the game plays, with its time —
the only way to check sound timing without ears. `SCOUNDREL_NO_AUDIO=1` runs it as a machine with
no audio device would.

Two conventions matter if you touch this code:

**Pure logic is written test-first.** The failing test comes before the implementation for
anything in `model`, `rules`, `runs`, `achievements`, `tutorial` or `audio`. Those packages are
headless by construction, so there is never a reason not to.

**UI is verified by screenshot, not by test.** Rendering cannot be asserted meaningfully in JUnit,
so changes to `screens` are checked by launching the real game, driving it with synthesised input
and reading the pixels back. When a screen accumulates logic that *could* be tested — a formatter,
a hit region, a frame timeline — that logic gets extracted into a pure class with a characterization
test written before the move, rather than left where it cannot be reached.

Design notes live in [`docs/design.md`](docs/design.md), [`docs/ui.md`](docs/ui.md) and
[`docs/audio.md`](docs/audio.md), and are kept in sync with the code rather than written once.

## Roadmap

Shipped in **1.0** — the game, complete and playable:

- [x] Pure model and rules engine — dealing, avoiding, combat, degradation, scoring
- [x] Card motion, per-card resolve effects, death cinematic
- [x] Procedural torchlit atmosphere — glow, flicker, drifting embers
- [x] Persisted high scores, lifetime statistics, achievements
- [x] Three difficulty modes as alternate rulesets
- [x] Guided tutorial that teaches every rule, including scoring
- [x] CI, coverage gate, self-contained desktop builds

Shipped in **2.0** — the art, and everything it dragged with it:

- [x] Pixel-art creatures, weapons and potions, with idle animation
- [x] Every screen redrawn on the pixel kit; Scene2D and both vector faces removed
- [x] A fixed design space rendered through an offscreen surface, on a snapping viewport
- [x] One shared screen frame, and a palette rule the build enforces

Shipped in **2.1** — sound:

- [x] 29 synthesized sound effects, each on its animation's beat, weighted by the card's value
- [x] Menu and run music, win and death cues, and a crackling torch on every screen
- [x] MUSIC and SOUND levels on the title, M to mute, the levels saved between launches
- [x] Every sound synthesized in Python and signed off by ear, kept as final

Shipped in **2.2**:

- [x] ESC leaves a run: asked first, recorded nowhere

Not planned, and deliberately so: mid-game save/resume, a replay format, online scores. A run is
a single sitting, which is the shape of the game.

## Author

Built by **Tomer Ben Ari** — [github.com/tomerba6](https://github.com/tomerba6).

## Credits

Scoundrel was designed by **Zach Gage and Kurt Bieg**. This repository is an independent,
non-commercial fan implementation built as a learning project, and is **not affiliated with,
endorsed by, or sponsored by** them. All credit for the game's design is theirs.

Licensed under the [MIT License](LICENSE); see [NOTICE.md](NOTICE.md) for the attribution terms.
