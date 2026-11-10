# Tiny Ages

A tiny settlement that lives at the edge of your screen and grows through the ages: a few villagers, a cave and a fire on a thin strip above your taskbar, with a world that goes on while you work. Time brings progress, your choices give it character, and nothing is ever demanded of you.

**Play it:** download the latest Windows build from [Releases](https://github.com/tthung1997/tiny-ages/releases), unzip it and run `TinyAges.exe`. See [`PLAYING.md`](PLAYING.md) for how it works.

## Project notes

- [MVP concept](docs/mvp-concept.md) — the initial idea and scope notes.
- [Engine and art direction](docs/engine-and-art.md) — Godot + LibreSprite decisions, style rules, pipeline.
- [Simulation core](docs/simulation.md) — the headless settlement sim: decisions, pacing, what is built.
- [Ages](docs/ages.md) — the long-term arc from the Cave Age onward, and the decisions so far.
- [Gameplay basics](docs/gameplay.md) — the player's role, resources, pacing, achievements and how ages are gated.
- [Art tools](tools/art/README.md) — scripts that generate the reference art (`art/reference/`).

## Godot project

The game lives in [`game/`](game/) (Godot **4.7**, standard build, GDScript).

1. Install [Godot 4.7](https://godotengine.org/download) (standard, not .NET).
2. In Godot choose **Import** and select `game/project.godot`, then press **F5**.
3. The [Godot AI](game/addons/godot_ai/README.md) editor plugin (MCP server for AI
   tooling) is committed and enabled, so it starts with the project — connect your
   MCP client from the **Godot AI** dock.

For command-line tooling, point `$env:GODOT` at a **console** build (or put
`godot_console` on `PATH`), then validate with `pwsh -File game/tools/check.ps1`.
Conventions are in [`.github/copilot-instructions.md`](.github/copilot-instructions.md).

## Releasing

Bump `config/version` in `game/project.godot` (the only place), merge it, then push a tag:

```
git tag v0.2.0
git push origin v0.2.0
```

The [Release workflow](.github/workflows/release.yml) installs Godot, runs the full check, builds the
Windows zip and publishes a GitHub Release with the zip, its SHA-256 and generated notes
(`.github/release-notes.md` plus the merged PRs). It refuses a tag that does not match `config/version`.
Every pull request, and **Actions > Release > Run workflow**, does the same without publishing, as a
dry run, so a PR shows whether the tests and the build pass. Public repos run Actions for free.

To build by hand: `pwsh -File game/tools/build_release.ps1` exports the Windows build and zips it with the
licences and `PLAYING.md` (as `README.txt`) into `game/build/TinyAges-<version>-windows.zip`, plus a SHA-256
file. It needs the Windows export templates for the engine version; `pwsh -File game/tools/install_godot.ps1`
installs the engine and templates (checksum-verified) on a fresh machine. The build is not code-signed, so
Windows SmartScreen warns on first run (`PLAYING.md` says so).

## License

MIT, see [`LICENSE`](LICENSE). The engine, font and editor plugin are covered in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
