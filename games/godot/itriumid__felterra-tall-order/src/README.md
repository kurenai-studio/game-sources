# Felterra: Tall Order

A crew of cats against giants. A human company has bought the forest they live in and moved in
with its machines, and to the humans, cats are pests. We're making them take cats seriously.

An auto-shooter roguelike set in the Nusantara seas of Felterra, a world of cats. Pixel art,
honest physics, and two ways to play: **Liberation**, the story, freeing the forest area by area
from the company clearing it; and **Endless**, a fresh clearing every run, where cooperative play
for one to four lives. More about it, and the downloads, on
[itrium.id/tall-order](https://itrium.id/tall-order).

It's a work in progress, built in the open: the design is in [`docs/design.md`](docs/design.md),
and everything in the game, built or planned, is in [`docs/catalog.md`](docs/catalog.md). What
runs so far: Tompel, a cat on four legs with a weapon in his mouth and another in his tail; seven
areas to free, each with its own goal and boss; a village the story brings back from ruin, and
the cast who live there, with portraits; level-up cards, gear, evolving weapons, dodge mutations
and support; Endless; and synthesized sound and music.

## Download

Builds for Windows, macOS (Apple Silicon and Intel) and Linux (x86-64 and ARM) are on the
[releases page](https://github.com/itriumid/felterra-tall-order/releases). Each is a zip: unpack it
and run the game inside.

The builds aren't signed by a publisher Windows or macOS knows yet, so each warns the first time:

- **Windows:** SmartScreen says it protected your PC. Choose **More info**, then **Run anyway**.
- **macOS:** it says the app can't be checked for malicious software. Open **System Settings →
  Privacy & Security**, find Felterra Tall Order near the bottom, and choose **Open Anyway**.
- **Linux:** if it won't start, make it executable: `chmod +x felterra_tall_order.x86_64`.

## Free, and how it will pay for itself

Tall Order is free to download and play, with no advertisements and nothing that tracks you. We
haven't worked out yet how it can pay its own way. Whatever we choose, we'll say so plainly
before it happens, and the game you can download stays free.

## How the art is made, for now

For now, the game's pixel art, sounds and music are made with AI tools. They're placeholders: a
way to build and test a whole game before there's money to pay anyone for it. Once Tall Order
earns enough, we want real artists and musicians to replace them, piece by piece, and to credit
them by name.

## Make it with us

If you draw pixel art, make sound or music, or build games, and Tall Order is something you'd
like to work on, write to us at [hello@itrium.id](mailto:hello@itrium.id). We'd love to hear from
you.

## Controls

| Keyboard | Gamepad | Action |
|---|---|---|
| W A S D or the arrow keys | Left stick | Move |
| Space | A | Dodge (a charge each; mutations from the cards change what it does) |
| 1 or 2 | Left bumper or up | Choose what you start with: nunchaku or handgun |
| T | X | Change how weapons choose a target (also in the settings) |
| B | | Blood on or off (also in the settings) |
| G | Y | Try on gear (until upgrades hand it out) |
| 1, 2, 3 | Bumpers and up | Play a choice from a level-up card |
| R | Down | Reroll the card |
| X with 1, 2 or 3 | B | Banish that choice for the rest of the run |
| Tab (hold) | Back | Read the cards in full |
| I | Left stick press | Gear and stats: what he carries, and every stat as it stands |
| Escape | Start | Pause: carry on, settings, start again, back to the village, leave |
| W A S D or the arrow keys | Left stick | In the village: walk about. The gate on its far side leads to a run |
| Enter | A | In the village, at a door: use what it holds (his pack, the smith's forge, the Elder's book, the weaver's looks, the map) |
| A and D, W and S | Stick | At the smithy and in his pack: change tab, and choose |
| Enter | A | In a cutscene: finish the line, or move on to the next |
| Enter | A | Home from a run: put away what's new |
| Escape | Start | In a cutscene: skip it |
| W and S, then Enter or Space | Stick, then A | Choose in the pause menu |
| A and D, or the arrows | Stick | Change a setting: graphics, audio volumes, aim and blood. Settings are kept for next time |
| Enter twice, on Reset all progress | A twice | Start the village and the best run over; the settings stay |
| F3 | | Frame rate and timings |
| F11 | | Full screen |

The cat's weapons choose a target and strike on their own; you move and dodge.

## Built with

[Godot](https://godotengine.org) 4.7, in GDScript, with the Compatibility renderer, for Windows,
macOS and Linux.

## Development

The font, Itrium Pixel, comes from [its own repository](https://github.com/itriumid/pixel-font)
as a git submodule, so clone with `--recurse-submodules`, or run `git submodule update --init`
after cloning.

```sh
# Run the tests (import once first on a fresh checkout)
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd

# Export every platform into build/release, as a release does (needs Godot's export templates)
GODOT=/path/to/godot tools/export.sh

# How long a simulation step takes with a horde of each size
timeout 300 godot --headless --path . --script tools/benchmark_horde.gd
```

## License

The code is free software under the [GNU General Public License, version 3](LICENSE). The name
Felterra and the game's logo aren't covered by that license: forks are welcome, under another
name.
