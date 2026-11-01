# Python Game Suite Finish-Out Design

Date: 2026-11-01
Status: Draft for user review
Repo: https://github.com/Onehand-Coding/python-game-suite

## Context

The repository is an inactive public Python project from July 2025. It advertises five games, a
pluggable discovery system, and both terminal and GUI Lucky9 modes. In reality it has no tests, no
CI, two explicit TODO functions in Lucky9, and a completely commented-out GUI.

Known defects:

- `lucky9/gui.py` and `lucky9/gui_engine.py` are entirely commented out. No GUI game is
  discovered, yet the README advertises "Terminal/GUI" and "modern GUI games".
- `lucky9/config.py` creates asset and data directories inside `src` at import time. This writes
  into the source tree and can fail for an installed package.
- `Lucky9` stores save data inside the package directory, which is not user-writable in a normal
  installation.
- `terminal.py` has two TODOs: `levelUp` and `collectPlayerDebt`. Their logic is entangled with
  printing, prompting, sleeping, and `sys.exit`.
- There are no tests and no CI. The README tells contributors to "ensure tests pass" and shows
  `ruff`, but pytest is not a declared dependency.
- The README's extension instructions reference a non-existent `common.game_base` and `GameBase`
  class. The real module is `common/game_template.py` and the class is `Game`.
- `main.py` discovery only catches `ImportError`, so one broken game module aborts the suite.
- The package declares Python 3.9 support while Ruff targets 3.10.
- `pygame` is a runtime dependency but only used by commented code.

## Goals

1. Make the Lucky9 GUI real and playable.
2. Harden all game logic with a real pytest suite.
3. Resolve the Lucky9 level and debt TODOs with testable engine methods.
4. Add CI, correct packaging, and rewrite stale documentation.
5. Keep the terminal Lucky9 save/load behavior working.

## Non-goals

- Online play, accounts, or a hosted service.
- External art or sound assets. The GUI uses pygame primitives and text.
- A full animation system. The GUI updates instantly on input.
- Save/load in the GUI. Persistence remains a terminal-game feature.
- New games beyond the existing five (six menu entries counting both Lucky9 modes).

## Architecture

Target files:

```
src/python_game_suite/
  main.py                         # discovery and menu
  common/game_template.py         # Game ABC
  hangman/                        # existing game
  mastermind/                     # existing game
  number_guessing/                # existing game
  rock_paper_scissors/            # existing game
  lucky9/
    config.py                     # user data directory only
    terminal_engine.py            # shared Lucky9 engine + Player + Dealer
    terminal.py                   # terminal UI and prompts
    gui_engine.py                 # pure Lucky9Session state machine
    gui.py                        # pygame view and event loop
    colors.py                     # shared color constants
tests/
  conftest.py
  test_main.py
  test_hangman.py
  test_mastermind.py
  test_number_guessing.py
  test_rock_paper_scissors.py
  test_lucky9_engine.py
  test_lucky9_terminal.py
  test_lucky9_gui_engine.py
  test_lucky9_gui.py
.github/workflows/ci.yml
README.md
CONTEXT.md
pyproject.toml
```

Responsibilities:

- `gui_engine.py`: pure state and rules. It must not import pygame.
- `gui.py`: pygame rendering and event translation only. It calls the session.
- `terminal_engine.py`: shared cards, players, dealers, round settlement, level progression, debt
  rules, and persistence.
- `terminal.py`: prompts, printing, and terminal-only commands.
- `main.py`: discovery, menu, and error isolation.

## Data directory

Replace package-local save data with a user-writable directory:

```python
def get_data_dir() -> Path:
    override = os.getenv("PYTHON_GAME_SUITE_DATA_DIR")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".local" / "share" / "python-game-suite"
```

- No directory is created at import time.
- `Lucky9.__init__` creates the directory lazily with `mkdir(parents=True, exist_ok=True)`.
- `Lucky9(player, data_dir=None)` accepts an override for tests.
- `clearData` removes only `lucky_data*` files, not every file in the directory.
- The README documents `PYTHON_GAME_SUITE_DATA_DIR`.

## Engine changes

`terminal_engine.Lucky9` gains:

- `settle_round(bet) -> str`: compare hands, transfer money, return `"player"`, `"dealer"`, or
  `"tie"`.
- `advance_level() -> Dealer | None`: increment level and return the new dealer, or return `None`
  at level 5. It does not print or exit.
- `debt_offer_available() -> bool`: true when `money * 0.5 >= debt >= 10_000`.
- `settle_debt(pay: bool) -> str`:
  - `pay=True`: subtract the debt, clear it, return `"paid"`.
  - `pay=False` and the player has refused fewer than 3 times: increment the refusal count, return
    `"refused"`.
  - `pay=False` and the refusal count is already 3: subtract double the debt, clear the debt,
    reset the refusal count, return `"penalty"`.
- The existing `Player`, `Dealer`, `createDeck`, `inviteDealer`, and save/load methods remain.

`terminal.py`:

- `levelUp()` calls `advance_level()`. If it returns a dealer, print it and pause. If it returns
  `None`, save and exit.
- `collectPlayerDebt()` checks `debt_offer_available()`, prompts, calls `settle_debt`, and prints
  the matching message.
- `checkWinner()` delegates to `settle_round`.
- The TODOs are removed.

## GUI session

`gui_engine.py` defines:

```python
class Phase(str, Enum):
    BETTING = "betting"
    PLAYER_TURN = "player_turn"
    ROUND_OVER = "round_over"
    GAME_OVER = "game_over"


class Lucky9Session:
    def __init__(self, player_name="Player", data_dir=None, deck_factory=None)
    phase: Phase
    message: str
    winner: str | None
    bet: int
    game: Lucky9

    def place_bet(self, amount: int) -> bool
    def hit(self) -> None
    def stand(self) -> None
    def next_round(self) -> None
    def restart(self) -> None
```

Rules:

- Bet options are `1_000`, `2_000`, and `5_000`.
- `place_bet` is valid only in `BETTING`, with an amount in the options and no more than
  `player.money`. It deals two cards to each side and moves to `PLAYER_TURN`.
- `hit` is valid only in `PLAYER_TURN` with exactly two player cards. It adds one card, sets
  `player.drewCard = True`, then resolves the round. The player cannot hit again.
- `stand` is valid only in `PLAYER_TURN`. It resolves the round.
- Resolution draws for the dealer while the dealer hand value is below 7, up to
  three cards, calls `game.settle_round(bet)`, and moves to `ROUND_OVER`.
- `next_round` clears hands and the bet. If the dealer is broke, it calls `advance_level()`.
  If no dealer remains, the player wins the game and the phase becomes `GAME_OVER`. If the player
  has less than the minimum bet, the phase becomes `GAME_OVER`. Otherwise it returns to `BETTING`.
- `restart` creates a fresh `Lucky9` with a fresh `Player` and returns to `BETTING`.
- The session reshuffles when fewer than 10 cards remain.
- `deck_factory` defaults to `Lucky9.createDeck`; tests inject a deterministic list.
- The session never calls `input`, `print`, `sleep`, or `sys.exit`.

## GUI view

`gui.py` defines `Lucky9Gui(Game)`:

- Window: 960x600, 60 FPS.
- `get_name()` returns `"Lucky9 (GUI)"`.
- `run()` calls `pygame.init()`, creates the display, runs the event loop, and calls
  `pygame.quit()` on exit.
- `render(surface)` draws:
  - Dark green table background and a title.
  - Level, player money, dealer money, bet, and hand values.
  - Dealer hand with the second card face down until the round ends.
  - Player hand face up.
  - Status or winner message.
  - Clickable chips and action buttons with keyboard hints.
- Card rendering uses pygame rectangles and text, not image files:
  - Rank text and a suit letter: `H`, `D`, `S`, `C`.
  - Hearts and diamonds use red; spades and clubs use black.
  - Face-down cards show a patterned blue back.
- `handle_event(event) -> bool` returns `False` to quit:
  - `Q` quits at any time.
  - `BETTING`: `1`, `2`, `3` place the corresponding bet.
  - `PLAYER_TURN`: `H` hits, `G` stands.
  - `ROUND_OVER`: `N` starts the next round.
  - `GAME_OVER`: `R` restarts.
  - Mouse clicks on the chip and action rectangles perform the same actions.
- The GUI does not save or load games.
- `pygame` is imported at module level; no display is created at import.

## Main menu

- `discover_games` imports every game module and finds `Game` subclasses.
- It catches `Exception` per module, prints a short warning, and continues.
- The menu sorts game names alphabetically for a stable order.
- Expected entries: Hangman, Lucky9 (GUI), Lucky9 (Terminal), Mastermind, Number Guessing,
  Rock, Paper, Scissors.
- Invalid menu input re-prompts. The exit option is always last.

## Testing

`tests/conftest.py`:

- Adds `src` to `sys.path`.
- Sets `SDL_VIDEODRIVER=dummy` and `SDL_AUDIODRIVER=dummy` before pygame imports.
- Provides a fixture that initializes pygame and quits it after the test.

Game tests:

- Hangman: word lookup by length, missing length error, valid/invalid length prompts, a winning
  round, a losing round.
- Mastermind: code uniqueness, guess validation, clue evaluation, win path, attempt-limit path.
- Number Guessing: lower/higher/win path, quit path, play-again validation.
- Rock, Paper, Scissors: move validation, quit mid-round, win/lose/tie scoring, play-again.

Lucky9 engine tests:

- Deck has 40 unique cards, 4 suits, ranks A through 10.
- Hand values: numeric ranks, ace as 1, modulo 10, three of a kind equals 9, two aces equal 9.
- Dealer levels map to the expected names and money.
- `advance_level` increments and returns a new dealer; returns `None` at level 5.
- `settle_round` transfers money for player, dealer, and tie results.
- Debt offer thresholds and the paid, refused, and penalty outcomes.
- Save, load, list, delete, and clear with a temporary data directory.

Terminal tests:

- `getPlayerBet` rejects non-numeric and over-budget bets, then accepts a valid bet.
- `borrowMoney` enforces the loan limit and increases money and debt.
- `checkDeckCount` reshuffles at 10 cards.
- `levelUp` advances, and at level 5 saves and exits.
- `collectPlayerDebt` calls `settle_debt` and prints the right result.
- `isBroke`.
- `TerminalLucky9.get_name`.

GUI session tests:

- Initial phase is `BETTING`.
- Invalid bets are rejected; a valid bet deals two cards to each side and moves to
  `PLAYER_TURN`.
- Hit adds one card and resolves; a second hit is rejected.
- Stand draws for the dealer below 7 and settles the bet.
- Dealer broke advances the level.
- Level 5 dealer broke ends the game.
- Player below the minimum bet ends the game.
- Restart resets level, money, and hands.

GUI view tests:

- Render each phase to an off-screen surface with no exception.
- Handle `Q`, bet chips, hit, stand, next, restart, and mouse clicks.
- Confirm a face-down dealer card becomes visible after the round resolves.

## Tooling and CI

`pyproject.toml`:

- `requires-python = ">=3.10"`.
- Keep `pygame>=2.5.0`.
- Dev dependencies: `pytest>=8.4`, `pytest-mock>=3.14`, `ruff>=0.6`.
- `[tool.pytest.ini_options]` with `testpaths = ["tests"]`.
- Keep Ruff at line length 88 and target py310.

`.github/workflows/ci.yml`:

1. Checkout.
2. Set up Python 3.12.
3. Set up uv.
4. `uv sync --extra dev`.
5. `uv run ruff check .`.
6. `uv run ruff format --check .`.
7. `uv run pytest`.
8. Set `SDL_VIDEODRIVER=dummy` and `SDL_AUDIODRIVER=dummy` for the job.

## Documentation

- README:
  - Describe six menu entries: the four classic games plus both Lucky9 modes.
  - GUI controls and terminal controls.
  - Correct `Game` and `common/game_template.py` extension instructions.
  - Data directory and `PYTHON_GAME_SUITE_DATA_DIR`.
  - Testing commands and CI.
  - Python 3.10+.
- `CONTEXT.md`: purpose, architecture, commands, decisions, gotchas, known limitations.
- `docs/screenshot.png`: generate a screenshot with an off-screen pygame render and reference it
  from the README.

## Acceptance criteria

1. `run-games` lists six entries and both Lucky9 modes launch.
2. The GUI is playable with keyboard and mouse: bet, hit, stand, next, restart, quit.
3. The GUI draws all four phases headlessly without error.
4. Terminal Lucky9 save/load still works and uses the user data directory.
5. The two Lucky9 TODOs are gone and covered by engine tests.
6. All game modules have tests.
7. `ruff check`, `ruff format --check`, and `pytest` pass locally and in CI.
8. The wheel includes `hangman/words.txt`.
9. README and CONTEXT match the implementation.
10. No data or asset directories are written into `src` at import time.

## Risks and mitigations

- Pygame headless behavior differs by platform. Mitigation: dummy SDL drivers in tests and CI.
- The GUI can become larger than "minimal". Mitigation: keyboard and mouse actions only, no
  animation, no sound, generated cards.
- The data-directory move could break existing saves. Mitigation: document the new location and
  keep the shelve file name; existing package-local saves are not migrated.
- Refactoring terminal globals could break prompts. Mitigation: keep terminal functions as thin
  wrappers and test them with mocked input.
- The discovery test depends on pygame import. Mitigation: pygame remains a required dependency
  and tests use dummy drivers.
