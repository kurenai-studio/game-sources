# Dreamrun

A 2D atmospheric puzzle-platformer in the style of Limbo and Inside, made with Godot 4 and GDScript. A child is trapped in a
nightmare and chased by a monster. They run, climb, swing on a rope, push crates, pull levers, and use traps (a falling
boulder, electricity, fire) to hold the monster back. After the last boss they wake up in a bright bedroom.

## Why this exists

**This is a learning project, not a product.** I built it to test what I learned about an AI-native software development
life cycle (SDLC) with Claude Code: writing a plan with a definition of done for each step, letting the AI implement
milestone by milestone, and checking every step with automated tests and bots instead of trusting it.

There is no business behind it: it is not for sale, has no monetisation, no backend and no accounts, and nothing about it
is meant to make money. It is an experiment in a way of working, and the game is the exercise.

> *Mục đích:* dự án này được làm để thực hành và kiểm chứng sau khi học quy trình phát triển phần mềm AI-native (AI native
> SDLC) với Claude Code. Đây không phải sản phẩm kinh doanh.

How the way of working shows up in the repository:

| Idea | Where to look |
|---|---|
| The brief that started everything | `PROMPT.md` |
| A living plan: scope, milestones, a definition of done and a check per step, known problems | `docs/PLAN.md` |
| Rules the AI must follow in this repo | `CLAUDE.md` |
| Design and level notes | `docs/GDD.md`, `docs/level-notes.md` |
| Every third-party asset must be recorded (there are none; all sound is generated) | `ASSETS.md` |
| Tests that play the game: scripted bots, a random-button bot, and a bot that plays like a person | `game/tests/` |

## Play it

**Download:** every tagged version has builds for Windows, Linux and macOS on the
[Releases page](https://github.com/tuanden0/dreamrun/releases). Unzip and run. The builds are not code-signed, so Windows
SmartScreen and macOS Gatekeeper will warn: on Windows choose "More info" then "Run anyway", on macOS right-click
`Dreamrun.app` and choose Open (or run `xattr -cr Dreamrun.app`).

**From source:** you need [Godot](https://godotengine.org) 4.7 (developed on 4.7.2). From the repository root:

```
godot --path game
```

The first time on a fresh checkout, import the project once: `godot --headless --path game --import`.

The game resumes from the last checkpoint you touched. To start over: `godot --path game -- --new-game`.

| Action | Keys |
|---|---|
| Move | Left / Right arrows (hold to go from a walk to a run) |
| Jump | Space |
| Use: pull a lever, grab a crate (hold), grab a rope in mid-air | E |
| Climb: hold with a jump to catch a ledge | W or Up arrow |
| Pause (icons only: resume, back to the checkpoint, quit) | Esc |

A gamepad works too. There is no text during play; the credits are the only place with words.

## Development

```
tools/test.sh                                   # the whole test run, under two minutes, headless
TEST_ONLY=chapter tools/test.sh                 # one test file at a time while iterating
godot --path game --editor                      # the editor
godot --path game --resolution 1920x1080 --script ../tools/fps.gd   # frame times at 1080p (needs a display)
bash tools/gen_audio.sh                         # rebuild the generated sound effects with ffmpeg
```

The tests start the real scenes and play them: each section of the chapter is played by a bot from its checkpoint, the
whole chapter in one run, wrong moves too (pushing into walls, skipping puzzles, standing still while chased), and a
recorder flags teleporting, impossible flight, falling through the floor and getting stuck on open ground.

GitHub Actions runs the tests on every push to `main` and every pull request (`.github/workflows/ci.yml`). Pushing a tag
such as `v1.0.0` runs the tests again, exports the game for the three platforms and publishes a release
(`.github/workflows/release.yml`; started by hand from the Actions tab it only keeps the builds as downloadable artifacts).

## Layout

```
game/        the Godot project (scripts/, scenes/, levels/, shaders/, assets/, tests/)
docs/        design notes, the plan, level notes
tools/       test runner, frame-time check, screenshot and animation contact-sheet scripts, the audio generator
PROMPT.md    the original brief
CLAUDE.md    conventions for the AI working in this repo
ASSETS.md    ledger of third-party assets
```

## Credits

Created by [tuanden0](https://github.com/tuanden0), developed with Claude Code by Anthropic, made with the Godot Engine.
All visuals are drawn in code and all sound is generated, so there is no third-party art or audio.

## License

MIT, see [LICENSE](LICENSE). It is a personal learning project: use the code however you like, but there is no support and
no warranty.
