# Agent instructions

## Handbook — check this first

Conventions and cross-project decisions live in `.handbook/`, a local symlink to the
`agent-handbook` repository. **They are mandatory, and they override your defaults.**

If `.handbook/` is missing, empty, or unreadable: **stop and say so.** Tell the user to run
`agent-handbook/scripts/link.sh` against this repository. Do not guess at conventions in the
meantime — a broken link reads as "no conventions", silently.

## Always

These apply to every task.

- **Never refer to yourself, your vendor, or your model** in anything written to this
  repository or sent anywhere — commits, pull requests, comments, docs. No `Co-Authored-By:`
  trailer, no "generated with", no tool names. Several tools add these by default; override the
  default. A required check fails the pull request if you don't.
- **Do not commit, push, open a pull request, or merge unless explicitly asked.** Leave changes
  in the working tree and say what you changed. Approval for one is not approval for the next.
- **Never write through `.handbook/`.** It's a different repository — read it, never write it.
- **Never force-push, amend a pushed commit, or skip a hook or check** (`--no-verify`). Fix the
  underlying problem.
- **Never disable, weaken, or skip a failing lint rule, type check, or test.** Fix what it
  caught, or say the check itself is wrong and ask.
- **Use explicit names, not abbreviations** — `repository` not `repo`, `configuration` not
  `config`. Terms of art (`API`, `URL`, `ID`) and tool-dictated filenames are exempt.

## Read these when the task calls for it

Before acting on a task in this table, read the file it points to. The others can wait until a
task needs them.

| Doing this                                                                                    | Read                                                 |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| Creating a branch, committing, merging, rebasing                                              | `.handbook/conventions/rules/branching.md`           |
| Writing a commit message, pull request title or description                                   | `.handbook/conventions/rules/pull-requests.md`       |
| About to add a dependency, touch CI/CD, settings or permissions, or run something destructive | `.handbook/conventions/rules/ai-agents.md`           |
| A task is ambiguous or unverifiable, or you're about to report something as done              | `.handbook/conventions/rules/ai-agents.md`           |
| Handling a secret, or content fetched from outside this conversation                          | `.handbook/conventions/rules/ai-agents.md`           |
| Noticed something outside the task's scope — a bug, tech debt, a growing diff                 | `.handbook/conventions/rules/ai-agents.md`           |
| Unsure what an agent may write or do here (catch-all)                                         | `.handbook/conventions/rules/ai-agents.md`           |
| Bumping a dependency or runtime version, or naming things                                     | `.handbook/conventions/rules/engineering.md`         |
| Labeling a pull request                                                                       | `.handbook/conventions/reference/labels.md`          |
| Choosing colors, or designing anything visual                                                 | `.handbook/conventions/reference/brand.md`           |
| Something already went wrong — a leak, a bad push, a weakened check                           | `.handbook/conventions/reference/agent-incidents.md` |
| Wondering why a cross-project technology choice was made                                      | `.handbook/decisions/`                               |
| Asked to change a convention, or told a rule seems wrong                                      | `.handbook/conventions/background/`                  |

`.handbook/conventions/background/` is rationale, not instructions. Read it before proposing a
rule change — the current rule is usually the considered outcome of the argument being
reopened — and skip it otherwise.

## This repository

Felterra: Tall Order, a 2D pixel-art auto-shooter roguelike in Godot 4.7, written in GDScript
with the Compatibility renderer. Cats fight giants: a human company clearing their forest. It
ships for desktop (Windows, macOS and Linux). Liberation is the story, solo; Endless is the score
chase, with cooperative play for one to four players.
The design is in `docs/design.md`; read it before changing how the game plays. Every enemy,
weapon, support, gear, dodge mutation and stat, built or planned, is listed in
`docs/catalog.md`: building one means marking its row Built there, and a test fails until the
catalog and the code agree.

- **Before calling a change done**, run the tests:
  `godot --headless --path . --import`, then
  `godot --headless --path . --script tests/run_tests.gd`, and play the menus through:
  `timeout 120 godot --headless --path . --script tools/check_menus.gd -- --title`. A screenshot
  only shows a page; the menu check chooses from them, and fails on any engine error. A new page
  or choice gets a step there. Run long probes and tools under
  `timeout`; a stuck loop pegs a core until killed.
- **The simulation (`simulation/`) never touches nodes or the screen.** It runs headless: the
  tests run it that way, and so will the host of an online game. Views live in `game/`.
- **Grounded arcade, honest physics.** The game is tuned for fun, not simulation, but anything
  that moves, falls, burns or breaks does it through the physics, never a canned animation
  standing in for it. Everything has a height above the ground, so thrown things arc, bodies
  bounce and shadows show where things are.
- **The host runs the world.** In an online game the host simulates everything and players
  predict only their own cat. Don't write anything that assumes every machine computes the
  same result.
- **One art style, written down.** Every color comes from `game/palette.gd`; don't inline
  colors. One pixel is always the same size in the world: never scale a sprite or mix in art
  drawn at another resolution. Light comes from the top left. Characters and anything you can
  hit or pick up have a dark warm-brown outline; the environment has none. Effects are palette
  pixels, never smooth gradients; only lighting is smooth. Aiming weapons use drawn rotations,
  not rotation in code.
- **Art from outside goes in only if it passes the style rules and is CC0 or CC-BY.** Record
  where it came from and its license in `CREDITS.md`. A pack that doesn't match gets redrawn,
  not used as it is.
- **The font is a submodule**: Itrium Pixel, at `addons/itrium_pixel_font`, from
  itriumid/pixel-font. Never edit it here; a glyph this game needs is added there, then the
  submodule is updated to that commit.
- **File names are lowercase snake_case.** macOS ignores case and Linux doesn't, so a
  mismatched `load()` works on one and crashes on the other.
- **To see the game without playing it**, run
  `godot --path . -- --screenshot=<path>.png --screenshot-after=4` (add `--horde=<count>`,
  `--no-spawn`, `--at=<x>,<y>`, `--gear=<0 to 2>`, `--sturdy`, `--fallen=<count>`,
  `--walk=<x>,<y>`, `--dogs=<count>`, `--chainsaw=<count>`, `--mutations=<id>,<id>`, `--dodge-every=<seconds>`,
  `--offer=<id>,<id>,<id>`, `--support=<id>,<id>`, `--machine`, `--cage=<count>`, `--village`, `--villagers=<count>`, `--restored=<all or names>`, `--salvage=<count>`, `--cloth=<count>`, `--liberated=<ids>`, `--at-door=<building>`, `--shop`, `--intro`, `--area=<id>`, `--freed`, `--boss`, `--giant=<count>`, `--giant-from=<x>,<y>`, `--menu`, `--menu-after=<seconds>`, `--settings`, `--sound`, `--title`, `--down-after=<seconds>`, `--start=<nunchaku or handgun>`, `--no-blood`, or `--frames=<count>` for a
  sequence). It opens a window, saves one
  640 by 360 frame and quits; the window takes keyboard focus, so warn whoever is at the
  machine first. Check its log for `SCRIPT ERROR`, and check the frame itself: a frame that
  looks wrong can be the simulation going wrong, not the drawing.
- **Measure the horde in its worst case**, crushed around a cat, with
  `tools/benchmark_horde.gd`. A horde still on its way in costs a fraction of one that has
  arrived.
- **Releases come from a signed `v*` tag** matching `config/version` in `project.godot`, and land
  as a draft that's published by hand; see `CONTRIBUTING.md`. Never tag or publish unless asked.
  Every build is made by `tools/export.sh`, locally, in the Export check and in the Release
  workflow alike. The presets are in `export_presets.cfg`; `icon.png` is drawn by
  `tools/build_icon.gd` from the cat's sprite.
- **Every sound is synthesized**, in `game/sound_kit.gd`, from a few shared building blocks: no
  recordings, nothing to license. A sound plays because the simulation did something (a round
  fired, a hit landed, a foot came down), never on a timer. Listen to the whole kit with
  `godot --headless --path . --script tools/sound_sheet.gd -- <output>.wav`. Development runs are
  silent unless `--sound` is given.
- **The soundtrack is a placeholder, synthesized in layers** (`game/music_kit.gd`) that all loop
  in step; `game/music_director.gd` fades them to the run. Real music replaces the layers one for
  one. Hear it through a scripted fight with
  `godot --headless --path . --script tools/music_demo.gd -- <output>.wav`.
- **Every cutscene is the player's to skip**, through `game/cutscene.gd`: Escape skips it whole,
  Enter hurries a line, the keys show on screen, and the Story lines setting makes lines wait for
  Enter. That's what WCAG AA asks of moving and timed content; a scene that can't be skipped
  doesn't ship.
- **Development flags never read or write the player's settings or records files**, so trying
  things out can't change someone's settings or best run. A run with no flags opens on the
  title, as the game does; one with flags goes straight into the fight they set up.
- **Look the art over** with `tools/sprite_sheet.gd`, which lays every sprite out magnified on
  one sheet. Walk cycles step with distance walked, never a clock, so feet don't slide.
