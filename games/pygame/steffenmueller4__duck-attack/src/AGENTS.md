# AGENTS.md

Duck Attack is a small Moorhuhn-style shooter built with Pygame (`pygame-ce`, imported as `pygame`).

## Commands

- Install: `pip install -r requirements-dev.txt` (editable install + dev tools)
- Run: `python -m duck_attack`
- Test: `pytest` (headless via `SDL_VIDEODRIVER=dummy` / `SDL_AUDIODRIVER=dummy`, set in
  `tests/conftest.py`)
- Lint/format: `ruff check .` and `ruff format .`
- Build the app for the current OS: `pip install -r requirements-package.txt`, then
  `pyinstaller packaging/duck_attack.spec --noconfirm` (output in `dist/`; `build/` and
  `dist/` are git-ignored)

## Conventions

- Specs in `specs/` are the source of truth for behavior (see `specs/README.md`). New
  features start as a proposal in `specs/changes/NNNN-name.md` from `TEMPLATE.md`;
  implement only once it is `Accepted`, then fold its requirements into the capability
  specs and set it to `Done`. Keep every requirement's "Verified by" test list accurate,
  and update the specs whenever behavior changes.
- Source lives in `src/duck_attack/`, tests in `tests/`.
- Game-wide constants (sizes, speeds, timings, colors, file paths) go in `settings.py`;
  don't hard-code tunable values elsewhere.
- Images live in `src/duck_attack/assets/images/`, sounds in `src/duck_attack/assets/sounds/`.
- Assets must have real transparency where needed; check with `file` (RGBA), since images
  that only show a checkerboard pattern are not actually transparent.
- Time-based logic takes `dt` (seconds) in `update(dt)` instead of reading the clock, so
  tests can drive it deterministically.
- Dependency ranges are declared in `pyproject.toml`; exact pins in `requirements*.txt`.
  Update both when adding a dependency. Dependabot only bumps the `requirements*.txt`
  pins; raise a `pyproject.toml` range by hand when a new minimum is actually needed.
- Keep `ruff check` and `pytest` passing before committing.
- Keep the docs current: with every change, update `README.md` (setup, how to play,
  layout) and `AGENTS.md` (commands, conventions, architecture, testing) in the same task.
- Everything the game loads at runtime must live under `src/duck_attack/assets/`: the
  PyInstaller spec bundles exactly that folder (as `duck_attack/assets`, so
  `settings.ASSETS_DIR` works unchanged in the frozen app).

## Architecture

- `game.py`: `Game` owns the loop (`handle_events` -> `update(dt)` -> `draw`) and a
  `State` machine: `NAME_ENTRY` (typing via `TEXTINPUT`, prefilled with the remembered
  name; Enter or click starts once the name is non-empty) -> `PLAYING` (30 s round) ->
  `ROUND_OVER` (final score, 10 s) -> `HIGHSCORES` (click goes back to `NAME_ENTRY`).
  `Game.shoot` adds the hit duck's `points` or subtracts `settings.MISS_PENALTY` on a
  miss (the score may go negative).
- `duck.py`: `Duck` sprite with a random distance (`scale`) that sets its size, speed
  and `points`; pixel-mask hit test; falls when shot. One duck flies at a time.
- `crosshair.py`: crosshair as the system color cursor (hotspot on the red dot).
- `hud.py`: `render_text` (shadowed text), cached `Label`, `Hud` (score + timer).
- `screens.py`: `NameEntryScreen`, `RoundOverScreen`, `HighScoreScreen` overlays.
- `highscores.py`: `HighScoreList`, top 10 persisted to `settings.HIGHSCORES_FILE`
  (`~/.duck-attack/highscores.json`); entries are identified by round start timestamp
  and carry the player `name` (empty for older entries, shown as `-`).
- `player.py`: `load_player_name` / `save_player_name`; the last name is saved to
  `settings.PLAYER_NAME_FILE` (`~/.duck-attack/player.txt`) when a round starts.
- `sounds.py`: `RandomSound` plays a random clip from a set (never the same twice in a
  row; silent without an audio device). Used for the single shot sound
  (`Game.shot_sound`, `settings.SHOT_SOUND`, on every click while playing, hit or miss)
  and by `AmbientSounds` for duck calls at random intervals.
- `packaging/`: `duck_attack.spec` (PyInstaller onedir build; on macOS also a
  `DuckAttack.app` bundle with the version from `pyproject.toml`), `launcher.py` (entry
  script), `icon.png` (made from the duck image by `make_icon.py`). `*.spec` is
  git-ignored except this one.
- `.github/`: `dependabot.yml` (weekly PRs: pip pins grouped as `dev-tools` and
  `packaging`, `pygame-ce` alone; all GitHub Actions in one group);
  `workflows/ci.yml` (ruff + pytest on push/PR); `workflows/release.yml` builds Windows
  x64, macOS arm64 (`macos-latest`) and macOS Intel (`macos-15-intel`), runs a headless
  smoke test (app must still be running after 10 s), uploads zips, and on a `vX.Y.Z` tag
  (must match `pyproject.toml`) creates a GitHub Release, or uploads the zips
  (`--clobber`) to an existing release with that tag. Builds are unsigned.

## Testing

- `tests/conftest.py` redirects `settings.HIGHSCORES_FILE` and `settings.PLAYER_NAME_FILE`
  to temp paths for every test; never write to the real files from tests.
- `Game()` starts in `NAME_ENTRY`; tests that need a running round use the
  `playing_game()` helper in `tests/test_game.py`.
- Tests that create a `Game` should call `pygame.quit()` at the end.

## Git

- Never commit or push. The maintainer commits and pushes manually; leave changes in the
  working tree and don't offer to commit.
