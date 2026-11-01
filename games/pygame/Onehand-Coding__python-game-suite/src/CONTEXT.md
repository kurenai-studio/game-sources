# Project Context

## Purpose

A local collection of classic terminal games plus a pygame Lucky9 GUI. It is a
demo and portfolio project, not a hosted service.

## Architecture

- `main.py` discovers `Game` subclasses and runs the menu.
- `common/game_template.py` defines the `Game` abstract base class.
- Each game package is self-contained.
- `lucky9/terminal_engine.py` owns cards, players, dealers, settlement, levels,
  debt rules, and shelve persistence.
- `lucky9/gui_engine.py` owns a pure `Lucky9Session` state machine.
- `lucky9/gui.py` owns pygame rendering and event translation.
- `lucky9/terminal.py` owns terminal prompts and commands.

## Data

Lucky9 saves use shelve under `~/.local/share/python-game-suite` by default.
`PYTHON_GAME_SUITE_DATA_DIR` overrides the location. The directory is created
lazily by `Lucky9`.

## Commands

```bash
uv sync --extra dev
uv run run-games
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv run python scripts/render_screenshot.py
```

## Decisions

- Share one Lucky9 engine between terminal and GUI.
- Keep the GUI session free of pygame so it is unit-testable.
- Draw cards with pygame primitives instead of bundling image assets.
- Cap both hands at three cards.
- Keep terminal save/load and omit GUI save/load.
- Use dummy SDL drivers in tests and CI.
- Use a user-writable data directory instead of writing under `src`.

## Gotchas

- Pygame needs `SDL_VIDEODRIVER=dummy` in headless tests.
- `pygame.init()` is called only inside `Lucky9Gui.run`, not at import.
- The GUI session is the source of truth for phases; the view must not mutate
  game state directly.
- `shelve` creates multiple `lucky_data*` files; `clearData` only removes those.
- `main.py` catches exceptions per module so one broken game does not hide the
  rest of the menu.
- `getHandValue` returns `"??"` when asked to hide the value. Cast it to `int`
  only in revealed contexts.

## Known Limitations

- The GUI has no animations, sound, or save/load.
- The terminal game is Tagalog-first and intentionally informal.
- Lucky9 levels are capped at 5.
