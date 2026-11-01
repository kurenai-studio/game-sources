# Python Game Suite Finish-Out Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish python-game-suite with a playable Lucky9 GUI, complete tests for all games, resolved Lucky9 TODOs, CI, correct packaging, and accurate docs.

**Architecture:** Shared Lucky9 rules live in `terminal_engine.py`. A pure `Lucky9Session` in `gui_engine.py` drives both tests and the pygame view in `gui.py`. Terminal Lucky9 keeps its prompts and persistence, delegating rules to the engine.

**Tech Stack:** Python 3.10+, pygame 2.6, pytest, ruff, uv, GitHub Actions.

**Git policy:** Do not run `git commit`, `git push`, or `git add` unless the user explicitly asks.

---

## File Map

Create or replace:

- `src/python_game_suite/lucky9/config.py`
- `src/python_game_suite/lucky9/terminal_engine.py`
- `src/python_game_suite/lucky9/terminal.py`
- `src/python_game_suite/lucky9/gui_engine.py`
- `src/python_game_suite/lucky9/gui.py`
- `src/python_game_suite/lucky9/colors.py`
- `src/python_game_suite/main.py`
- `pyproject.toml`
- `.github/workflows/ci.yml`
- `tests/conftest.py`
- `tests/test_config.py`
- `tests/test_lucky9_engine.py`
- `tests/test_lucky9_terminal.py`
- `tests/test_lucky9_gui_engine.py`
- `tests/test_lucky9_gui.py`
- `tests/test_main.py`
- `tests/test_hangman.py`
- `tests/test_mastermind.py`
- `tests/test_number_guessing.py`
- `tests/test_rock_paper_scissors.py`
- `scripts/render_screenshot.py`
- `docs/screenshot.png`
- `README.md`
- `CONTEXT.md`

Do not touch:

- `LICENSE`
- `hangman/words.txt` content.

---

## Task 1: Data Directory, Dev Dependencies, and Test Bootstrap

**Files:**
- Replace: `src/python_game_suite/lucky9/config.py`
- Modify: `pyproject.toml`
- Create: `.github/workflows/ci.yml`
- Create: `tests/conftest.py`
- Create: `tests/test_config.py`

- [ ] **Step 1: Write the failing config tests**

Create `tests/conftest.py`:

```python
# ruff: noqa: E402
import os
import sys
from pathlib import Path

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")
os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

import pytest


@pytest.fixture
def pygame_display():
    pygame = pytest.importorskip("pygame")
    pygame.init()
    yield pygame
    pygame.quit()
```

Create `tests/test_config.py`:

```python
from pathlib import Path

from python_game_suite.lucky9 import config


def test_get_data_dir_default(monkeypatch):
    monkeypatch.delenv("PYTHON_GAME_SUITE_DATA_DIR", raising=False)
    assert config.get_data_dir() == (
        Path.home() / ".local" / "share" / "python-game-suite"
    )


def test_get_data_dir_env(monkeypatch, tmp_path):
    monkeypatch.setenv("PYTHON_GAME_SUITE_DATA_DIR", str(tmp_path))
    assert config.get_data_dir() == tmp_path
```

- [ ] **Step 2: Run the config tests and verify they fail**

Run:

```bash
uv run pytest tests/test_config.py -q
```

Expected: FAIL because `get_data_dir` does not exist.

- [ ] **Step 3: Replace `config.py`**

```python
from __future__ import annotations

import os
from pathlib import Path


def get_data_dir() -> Path:
    override = os.getenv("PYTHON_GAME_SUITE_DATA_DIR")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".local" / "share" / "python-game-suite"


DATA_DIR = get_data_dir()
```

- [ ] **Step 4: Update `pyproject.toml`**

Replace the metadata, dependency, dev, and test sections:

```toml
[project]
name = "python-game-suite"
version = "1.1.0"
description = "A collection of classic terminal and GUI games implemented in Python."
readme = "README.md"
requires-python = ">=3.10"
authors = [
    { name = "Onehand Coding", email = "Onehand.coding433@gmail.com" },
]
dependencies = [
    "pygame>=2.5.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.4",
    "pytest-mock>=3.14",
    "ruff>=0.6",
]

[project.scripts]
run-games = "python_game_suite.main:main"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra"

[tool.ruff]
line-length = 88
target-version = "py310"

[tool.ruff.lint]
select = ["E", "F", "W", "I"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
```

Keep the existing `[build-system]` block.

- [ ] **Step 5: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      SDL_VIDEODRIVER: dummy
      SDL_AUDIODRIVER: dummy
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Set up uv
        uses: astral-sh/setup-uv@v6
        with:
          enable-cache: true

      - name: Install dependencies
        run: uv sync --extra dev

      - name: Lint
        run: uv run ruff check .

      - name: Format check
        run: uv run ruff format --check .

      - name: Test
        run: uv run pytest
```

- [ ] **Step 6: Install and run the config tests**

Run:

```bash
uv sync --extra dev
uv run pytest tests/test_config.py -q
```

Expected: 2 passed.

---

## Task 2: Lucky9 Engine Rules

**Files:**
- Modify: `src/python_game_suite/lucky9/terminal_engine.py`
- Create: `tests/test_lucky9_engine.py`

- [ ] **Step 1: Write the failing engine tests**

Create `tests/test_lucky9_engine.py`:

```python
import pytest

from python_game_suite.lucky9.terminal_engine import Dealer, Lucky9, Player


def make_game(tmp_path):
    return Lucky9(Player("Test"), data_dir=tmp_path)


def test_create_deck_has_40_unique_cards():
    deck = Lucky9.createDeck()
    assert len(deck) == 40
    assert len(set(deck)) == 40
    assert {suit for _, suit in deck} == {
        chr(9830),
        chr(9829),
        chr(9824),
        chr(9827),
    }
    assert {rank for rank, _ in deck} == {
        "A",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10",
    }


def test_hand_values():
    player = Player("Test")
    player.hand = [("A", "s")]
    assert player.getHandValue() == 1
    player.hand = [("9", "s")]
    assert player.getHandValue() == 9
    player.hand = [("7", "s"), ("8", "h")]
    assert player.getHandValue() == 5
    player.hand = [("A", "s"), ("A", "h")]
    assert player.getHandValue() == 9
    player.hand = [("3", "s"), ("3", "h"), ("3", "d")]
    assert player.getHandValue() == 9
    player.hand = [("A", "s")]
    assert player.getHandValue(revealHandValue=False) == "??"


def test_invite_dealer_levels(tmp_path):
    game = make_game(tmp_path)
    game.level = 1
    assert game.inviteDealer().name == "Ace"
    game.level = 5
    dealer = game.inviteDealer()
    assert dealer.name == "Robin"
    assert dealer.money == 1_000_000
    game.level = 6
    with pytest.raises(ValueError):
        game.inviteDealer()


def test_advance_level(tmp_path):
    game = make_game(tmp_path)
    assert game.level == 1
    dealer = game.advance_level()
    assert game.level == 2
    assert dealer.name == "Joko"
    game.level = 5
    assert game.advance_level() is None
    assert game.level == 5


def test_settle_round_player_win(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("9", "s")]
    game.dealer.hand = [("5", "s")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "player"
    assert game.player.money == 11_000
    assert game.dealer.money == 99_000


def test_settle_round_dealer_win(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("5", "s")]
    game.dealer.hand = [("9", "s")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "dealer"
    assert game.player.money == 9_000
    assert game.dealer.money == 101_000


def test_settle_round_tie(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("5", "s")]
    game.dealer.hand = [("5", "h")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "tie"
    assert game.player.money == 10_000
    assert game.dealer.money == 100_000


def test_debt_offer_available():
    player = Player("Test")
    player.money = 20_000
    player.debt = 10_000
    game = Lucky9.__new__(Lucky9)
    game.player = player
    assert game.debt_offer_available() is True
    player.debt = 9_999
    assert game.debt_offer_available() is False
    player.money = 10_000
    player.debt = 10_000
    assert game.debt_offer_available() is False


def test_settle_debt_paid():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    assert game.settle_debt(True) == "paid"
    assert game.player.money == 40_000
    assert game.player.debt == 0


def test_settle_debt_refused():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    assert game.settle_debt(False) == "refused"
    assert game.player.money == 50_000
    assert game.player.debt == 10_000
    assert game.player.timesRefusedToPay == 1


def test_settle_debt_penalty():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    game.player.timesRefusedToPay = 3
    assert game.settle_debt(False) == "penalty"
    assert game.player.money == 30_000
    assert game.player.debt == 0
    assert game.player.timesRefusedToPay == 0


def test_save_load_list_delete_and_clear(tmp_path):
    game = make_game(tmp_path)
    game.player.name = "Alice"
    game.player.money = 12_345
    game.player.debt = 1_000
    game.level = 2
    game.saveData()
    assert "Alice" in game.getPlayerNames()

    loaded = make_game(tmp_path)
    loaded.player.name = "Alice"
    loaded.loadGameData("Alice")
    assert loaded.player.money == 12_345
    assert loaded.player.debt == 1_000
    assert loaded.level == 2

    loaded.deletePlayerData("Alice")
    assert "Alice" not in loaded.getPlayerNames()

    game.saveData()
    game.clearData()
    assert game.getPlayerNames() == []
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
uv run pytest tests/test_lucky9_engine.py -q
```

Expected: FAIL because `advance_level`, `settle_round`, and the debt methods do not exist.

- [ ] **Step 3: Update `terminal_engine.py`**

Replace the `Lucky9` class with the following, keeping the existing `Player` and
`Dealer` classes below it. Add `self.drewCard = False` to `Player.__init__`.

```python
from __future__ import annotations

import random
import shelve
from pathlib import Path

from .config import DATA_DIR


class Lucky9:
    def __init__(self, player, data_dir: Path | None = None):
        self.dealers = {
            5: {"Robin": 1_000_000},
            4: {"Caesar": 800_000},
            3: {"Jeric": 600_000},
            2: {"Joko": 400_000},
            1: {"Ace": 200_000},
        }
        self.level = 1
        self.player = player
        self.deck = self.createDeck()
        self.dealer = self.inviteDealer()
        self.dataFolder = Path(data_dir) if data_dir is not None else DATA_DIR
        self.dataFolder.mkdir(parents=True, exist_ok=True)
        self.database = self.dataFolder / "lucky_data"

    @staticmethod
    def createDeck():
        suits = [
            chr(9830),
            chr(9829),
            chr(9824),
            chr(9827),
        ]
        ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        cards = [(rank, suit) for rank in ranks for suit in suits]
        random.shuffle(cards)
        return cards

    def inviteDealer(self):
        dealer = self.dealers.get(self.level)
        if dealer is None:
            raise ValueError(f"No dealer configured for level {self.level}")
        dealerName = list(dealer.keys())[0]
        dealerMoney = dealer.get(dealerName)
        return Dealer(dealerName, dealerMoney)

    def settle_round(self, bet: int) -> str:
        player_value = self.player.getHandValue()
        dealer_value = self.dealer.getHandValue()
        if player_value < dealer_value:
            self.player.money -= bet
            self.dealer.money += bet
            return "dealer"
        if player_value > dealer_value:
            self.player.money += bet
            self.dealer.money -= bet
            return "player"
        return "tie"

    def advance_level(self) -> Dealer | None:
        if self.level >= 5:
            return None
        self.level += 1
        self.dealer = self.inviteDealer()
        return self.dealer

    def debt_offer_available(self) -> bool:
        return self.player.money * 0.5 >= self.player.debt >= 10_000

    def settle_debt(self, pay: bool) -> str:
        if pay:
            self.player.money -= self.player.debt
            self.player.debt = 0
            return "paid"
        if self.player.timesRefusedToPay == 3:
            self.player.money -= self.player.debt * 2
            self.player.debt = 0
            self.player.timesRefusedToPay = 0
            return "penalty"
        self.player.timesRefusedToPay += 1
        return "refused"

    def getPlayerNames(self):
        with shelve.open(self.database) as db:
            return list(db.keys())

    def saveData(self, name=""):
        if not name:
            name = self.player.name
        with shelve.open(self.database, writeback=True) as db:
            db[name] = {
                "level": self.level,
                "money": self.player.money,
                "debt": self.player.debt,
                "dealer name": self.dealer.name,
                "dealer money": self.dealer.money,
                "times refused to pay": self.player.timesRefusedToPay,
            }

    def loadGameData(self, name):
        with shelve.open(self.database) as db:
            self.level = db[name]["level"]
            self.player.debt = db[name]["debt"]
            self.player.money = db[name]["money"]
            self.player.timesRefusedToPay = db[name]["times refused to pay"]
            dealerName = db[name]["dealer name"]
            dealerMoney = db[name]["dealer money"]
            self.dealer = Dealer(dealerName, dealerMoney)

    def deletePlayerData(self, name):
        with shelve.open(self.database) as db:
            del db[name]

    def clearData(self):
        for file in self.dataFolder.glob("lucky_data*"):
            file.unlink()
```

Keep `Player` and `Dealer` unchanged, but add `self.drewCard = False` in `Player.__init__`.

- [ ] **Step 4: Run the engine tests**

Run:

```bash
uv run pytest tests/test_lucky9_engine.py -q
```

Expected: all engine tests pass.

---

## Task 3: Terminal TODO Refactor

**Files:**
- Modify: `src/python_game_suite/lucky9/terminal.py`
- Create: `tests/test_lucky9_terminal.py`

- [ ] **Step 1: Write the failing terminal tests**

Create `tests/test_lucky9_terminal.py`:

```python
import builtins

import pytest

from python_game_suite.lucky9 import terminal
from python_game_suite.lucky9.terminal_engine import Lucky9, Player


def make_game(tmp_path):
    game = Lucky9(Player("Test"), data_dir=tmp_path)
    terminal.lucky9 = game
    return game


def feed(monkeypatch, values):
    iterator = iter(values)
    monkeypatch.setattr(builtins, "input", lambda *_: next(iterator))


def test_is_broke():
    assert terminal.isBroke(0) is True
    assert terminal.isBroke(1) is False


def test_get_player_bet_validates_then_accepts(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 10_000
    feed(monkeypatch, ["abc", "0", "999999", "500"])
    terminal.getPlayerBet()
    assert game.player.bet == 500


def test_borrow_money_limit(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 1_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: True)
    feed(monkeypatch, ["0", "6000", "2000"])
    assert terminal.borrowMoney() is True
    assert game.player.money == 3_000
    assert game.player.debt == 2_000


def test_borrow_money_declined(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 1_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: False)
    assert terminal.borrowMoney() is None
    assert game.player.money == 1_000


def test_check_winner_delegates(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("9", "s")]
    game.dealer.hand = [("5", "s")]
    game.player.money = 10_000
    game.player.bet = 1_000
    assert terminal.checkWinner() == "player"
    assert game.player.money == 11_000


def test_check_deck_count_reshuffles(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.deck = game.deck[:10]
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    feed(monkeypatch, [""])
    terminal.checkDeckCount()
    assert len(game.deck) == 40


def test_level_up_advances(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.level = 4
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    feed(monkeypatch, [""])
    terminal.levelUp()
    assert game.level == 5
    assert game.dealer.name == "Robin"


def test_level_up_at_max_saves_and_exits(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.level = 5
    calls = []
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    monkeypatch.setattr(terminal, "saveGame", lambda: calls.append("save"))
    feed(monkeypatch, [""])
    with pytest.raises(SystemExit):
        terminal.levelUp()
    assert calls == ["save"]


def test_collect_debt_paid(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 50_000
    game.player.debt = 10_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: True)
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    feed(monkeypatch, [""])
    terminal.collectPlayerDebt()
    assert game.player.debt == 0
    assert game.player.money == 40_000


def test_collect_debt_refused(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 50_000
    game.player.debt = 10_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: False)
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    terminal.collectPlayerDebt()
    assert game.player.debt == 10_000
    assert game.player.timesRefusedToPay == 1


def test_collect_debt_penalty(tmp_path, monkeypatch):
    game = make_game(tmp_path)
    game.player.money = 50_000
    game.player.debt = 10_000
    game.player.timesRefusedToPay = 3
    monkeypatch.setattr(terminal, "yesOrNo", lambda: False)
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    feed(monkeypatch, [""])
    terminal.collectPlayerDebt()
    assert game.player.debt == 0
    assert game.player.money == 30_000


def test_terminal_game_name():
    assert terminal.TerminalLucky9.get_name() == "Lucky9 (Terminal)"
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
uv run pytest tests/test_lucky9_terminal.py -q
```

Expected: FAIL because the TODOs still contain the old logic and the name is wrong.

- [ ] **Step 3: Update `terminal.py`**

Replace `checkWinner`:

```python
def checkWinner():
    return lucky9.settle_round(lucky9.player.bet)
```

Replace `levelUp`:

```python
def levelUp():
    old_dealer = lucky9.dealer
    new_dealer = lucky9.advance_level()
    if new_dealer is None:
        print(
            f"\nUyy Congrats panalo kana!!!, maari mo ng i bangko iyang "
            f"{lucky9.player.money:,} Pesos mo."
        )
        time.sleep(2)
        input()
        saveGame()
        sys.exit()
        return

    print(f"\nUbos na ang pera ni {old_dealer.name} :)")
    print("\nmagpapalit ng bangka...")
    time.sleep(3)
    input("\n\tgame?")
    print(f"\nbagong Bangka:\n{new_dealer}")
```

Replace `collectPlayerDebt`:

```python
def collectPlayerDebt():
    if not lucky9.debt_offer_available():
        return

    print("\nHuy malaki laki na ang pera mo ah, magbabayad kana ba ng utang?")
    print(f"{lucky9.player.debt:,} Pesos ang utang mo.")
    refusals = lucky9.player.timesRefusedToPay
    outcome = lucky9.settle_debt(yesOrNo())

    if outcome == "penalty":
        print(
            f"\n{refusals} beses kanang umiwas magbayad, "
            "babawasan ng doble ang pera mo."
        )
        time.sleep(2)
        print(lucky9.player)
        input("\n\tGame?")
    elif outcome == "refused":
        print("\nnaku! pagka kuripot naman?")
        time.sleep(2)
    else:
        print("\nnagbabayad ng utang...")
        time.sleep(3)
        print("\nAyan bayad na utang mo.")
        time.sleep(1)
        print(f"{lucky9.player}")
        input("\n\tGame?")
```

Change the game name:

```python
    @staticmethod
    def get_name():
        return "Lucky9 (Terminal)"
```

- [ ] **Step 4: Run the terminal tests**

Run:

```bash
uv run pytest tests/test_lucky9_terminal.py -q
```

Expected: all terminal tests pass.

## Task 4: Lucky9 GUI Session

**Files:**
- Replace: `src/python_game_suite/lucky9/gui_engine.py`
- Create: `tests/test_lucky9_gui_engine.py`

- [ ] **Step 1: Write the failing session tests**

Create `tests/test_lucky9_gui_engine.py`:

```python
from python_game_suite.lucky9.gui_engine import (
    BET_OPTIONS,
    Lucky9Session,
    Phase,
)

FILLER = [("5", "S")] * 30


def deck_with_top(*cards):
    return FILLER + list(reversed(cards))


def make_session(tmp_path, *cards):
    return Lucky9Session(
        player_name="Test",
        data_dir=tmp_path,
        deck_factory=lambda: deck_with_top(*cards),
    )


def test_initial_phase_and_money(tmp_path):
    session = make_session(tmp_path)
    assert session.phase is Phase.BETTING
    assert session.player.money == 10_000
    assert session.bet == 0
    assert session.can_bet is True


def test_invalid_bets_are_rejected(tmp_path):
    session = make_session(tmp_path)
    assert session.place_bet(999) is False
    assert session.place_bet(50_000) is False
    assert session.phase is Phase.BETTING


def test_place_bet_deals_two_cards_each(tmp_path):
    session = make_session(
        tmp_path, ("A", "S"), ("9", "S"), ("5", "S"), ("2", "S")
    )
    assert session.place_bet(1_000) is True
    assert session.phase is Phase.PLAYER_TURN
    assert session.player.hand == [("A", "S"), ("5", "S")]
    assert session.dealer.hand == [("9", "S"), ("2", "S")]
    assert session.bet == 1_000


def test_hit_adds_one_card_and_resolves(tmp_path):
    session = make_session(
        tmp_path,
        ("2", "S"),
        ("7", "S"),
        ("3", "S"),
        ("2", "S"),
        ("2", "S"),
    )
    session.place_bet(1_000)
    session.hit()
    assert len(session.player.hand) == 3
    assert session.phase is Phase.ROUND_OVER
    assert session.winner == "dealer"
    assert session.player.money == 9_000
    assert session.can_hit is False


def test_stand_draws_for_dealer_below_seven(tmp_path):
    session = make_session(
        tmp_path,
        ("8", "S"),
        ("2", "S"),
        ("1", "S"),
        ("2", "S"),
        ("3", "S"),
    )
    session.place_bet(1_000)
    session.stand()
    assert len(session.dealer.hand) == 3
    assert session.winner == "player"
    assert session.player.money == 11_000


def test_next_round_resets_table(tmp_path):
    session = make_session(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    session.place_bet(1_000)
    session.stand()
    session.next_round()
    assert session.phase is Phase.BETTING
    assert session.bet == 0
    assert session.player.hand == []
    assert session.dealer.hand == []


def test_dealer_broke_advances_level(tmp_path):
    session = make_session(
        tmp_path, ("9", "S"), ("5", "S"), ("9", "S"), ("2", "S")
    )
    session.place_bet(1_000)
    session.stand()
    session.dealer.money = 0
    session.next_round()
    assert session.level == 2
    assert session.dealer.name == "Joko"
    assert session.phase is Phase.BETTING


def test_level_five_dealer_broke_ends_game(tmp_path):
    session = make_session(tmp_path)
    session.game.level = 5
    session.dealer.money = 0
    session.phase = Phase.ROUND_OVER
    session.next_round()
    assert session.phase is Phase.GAME_OVER


def test_player_broke_ends_game(tmp_path):
    session = make_session(tmp_path)
    session.player.money = 500
    session.phase = Phase.ROUND_OVER
    session.next_round()
    assert session.phase is Phase.GAME_OVER


def test_restart_resets_progress(tmp_path):
    session = make_session(tmp_path)
    session.game.level = 4
    session.player.money = 1
    session.restart()
    assert session.level == 1
    assert session.player.money == 10_000
    assert session.phase is Phase.BETTING


def test_session_reshuffles_low_deck(tmp_path):
    session = make_session(
        tmp_path, ("A", "S"), ("9", "S"), ("5", "S"), ("2", "S")
    )
    session.game.deck = session.game.deck[-5:]
    session.place_bet(1_000)
    assert len(session.game.deck) >= 30
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
uv run pytest tests/test_lucky9_gui_engine.py -q
```

Expected: FAIL because `gui_engine.py` is still commented out.

- [ ] **Step 3: Replace `gui_engine.py`**

```python
from __future__ import annotations

from collections.abc import Callable
from enum import Enum
from pathlib import Path

from .terminal_engine import Dealer, Lucky9, Player

BET_OPTIONS = (1_000, 2_000, 5_000)


class Phase(str, Enum):
    BETTING = "betting"
    PLAYER_TURN = "player_turn"
    ROUND_OVER = "round_over"
    GAME_OVER = "game_over"


class Lucky9Session:
    def __init__(
        self,
        player_name: str = "Player",
        data_dir: Path | None = None,
        deck_factory: Callable[[], list] | None = None,
    ):
        self._deck_factory = deck_factory or Lucky9.createDeck
        self._data_dir = data_dir
        self._player_name = player_name
        self.game = self._new_game()
        self.phase = Phase.BETTING
        self.message = "Choose a bet to start."
        self.winner: str | None = None
        self.bet = 0

    def _new_game(self) -> Lucky9:
        game = Lucky9(Player(self._player_name), data_dir=self._data_dir)
        game.deck = list(self._deck_factory())
        return game

    @property
    def player(self) -> Player:
        return self.game.player

    @property
    def dealer(self) -> Dealer:
        return self.game.dealer

    @property
    def level(self) -> int:
        return self.game.level

    @property
    def can_bet(self) -> bool:
        return self.phase is Phase.BETTING and any(
            amount <= self.player.money for amount in BET_OPTIONS
        )

    @property
    def can_hit(self) -> bool:
        return self.phase is Phase.PLAYER_TURN and len(self.player.hand) == 2

    @property
    def can_stand(self) -> bool:
        return self.phase is Phase.PLAYER_TURN

    @property
    def can_next(self) -> bool:
        return self.phase is Phase.ROUND_OVER

    def place_bet(self, amount: int) -> bool:
        if self.phase is not Phase.BETTING:
            return False
        if amount not in BET_OPTIONS or amount > self.player.money:
            self.message = "That bet is not available."
            return False
        self._ensure_deck()
        self.bet = amount
        self.player.hand = []
        self.dealer.hand = []
        self.winner = None
        for _ in range(2):
            self.player.hand.append(self.game.deck.pop())
            self.dealer.hand.append(self.game.deck.pop())
        self.phase = Phase.PLAYER_TURN
        self.message = "Hit or stand?"
        return True

    def _ensure_deck(self) -> None:
        if len(self.game.deck) < 10:
            self.game.deck = list(self._deck_factory())

    def hit(self) -> None:
        if not self.can_hit:
            return
        self._ensure_deck()
        self.player.hand.append(self.game.deck.pop())
        self.player.drewCard = True
        self._resolve_round()

    def stand(self) -> None:
        if not self.can_stand:
            return
        self.player.drewCard = False
        self._resolve_round()

    def _resolve_round(self) -> None:
        self._ensure_deck()
        while (
            int(self.dealer.getHandValue()) < 7
            and len(self.dealer.hand) < 3
        ):
            self.dealer.hand.append(self.game.deck.pop())
        self.winner = self.game.settle_round(self.bet)
        if self.winner == "player":
            self.message = f"You win {self.bet:,} pesos."
        elif self.winner == "dealer":
            self.message = f"The dealer wins {self.bet:,} pesos."
        else:
            self.message = "It's a tie."
        self.phase = Phase.ROUND_OVER

    def next_round(self) -> None:
        if self.phase is not Phase.ROUND_OVER:
            return
        self.player.hand = []
        self.dealer.hand = []
        self.bet = 0
        self.winner = None
        self.message = "Choose a bet to start."
        if self.dealer.money <= 0:
            new_dealer = self.game.advance_level()
            if new_dealer is None:
                self.phase = Phase.GAME_OVER
                self.message = "You beat every dealer. You win the game!"
                return
            self.message = f"Level {self.level}: {new_dealer.name} sits down."
        if self.player.money < min(BET_OPTIONS):
            self.phase = Phase.GAME_OVER
            self.message = "You are out of money. Restart to play again."
            return
        self.phase = Phase.BETTING

    def restart(self) -> None:
        self.game = self._new_game()
        self.phase = Phase.BETTING
        self.bet = 0
        self.winner = None
        self.message = "Choose a bet to start."
```

- [ ] **Step 4: Run the session tests**

Run:

```bash
uv run pytest tests/test_lucky9_gui_engine.py -q
```

Expected: all session tests pass.

---

## Task 5: Pygame View

**Files:**
- Modify: `src/python_game_suite/lucky9/colors.py`
- Replace: `src/python_game_suite/lucky9/gui.py`
- Create: `tests/test_lucky9_gui.py`

- [ ] **Step 1: Write the failing GUI tests**

Create `tests/test_lucky9_gui.py`:

```python
import pytest

from python_game_suite.lucky9.gui import Lucky9Gui
from python_game_suite.lucky9.gui_engine import Lucky9Session, Phase

FILLER = [("5", "S")] * 30


def deck_with_top(*cards):
    return FILLER + list(reversed(cards))


def make_gui(tmp_path, *cards):
    session = Lucky9Session(
        player_name="Test",
        data_dir=tmp_path,
        deck_factory=lambda: deck_with_top(*cards),
    )
    return Lucky9Gui(session), session


def test_render_all_phases(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    for phase in Phase:
        session.phase = phase
        gui.render(surface)


def test_keyboard_flow(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    gui.render(surface)

    event = pygame_display.event.Event(
        pygame_display.KEYDOWN, key=pygame_display.K_1
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.PLAYER_TURN

    event = pygame_display.event.Event(
        pygame_display.KEYDOWN, key=pygame_display.K_g
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER

    event = pygame_display.event.Event(
        pygame_display.KEYDOWN, key=pygame_display.K_n
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.BETTING

    event = pygame_display.event.Event(
        pygame_display.KEYDOWN, key=pygame_display.K_q
    )
    assert gui.handle_event(event) is False


def test_mouse_chip_places_bet(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    gui.render(surface)
    rect = gui.buttons["bet:1000"]
    event = pygame_display.event.Event(
        pygame_display.MOUSEBUTTONDOWN, button=1, pos=rect.center
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.PLAYER_TURN


def test_mouse_action_stand(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    session.place_bet(1_000)
    gui.render(surface)
    rect = gui.buttons["stand"]
    event = pygame_display.event.Event(
        pygame_display.MOUSEBUTTONDOWN, button=1, pos=rect.center
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER


def test_restart_from_game_over(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path)
    surface = pygame_display.Surface((960, 600))
    session.phase = Phase.GAME_OVER
    gui.render(surface)
    event = pygame_display.event.Event(
        pygame_display.KEYDOWN, key=pygame_display.K_r
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.BETTING


def test_quit_event(pygame_display, tmp_path):
    gui, _ = make_gui(tmp_path)
    event = pygame_display.event.Event(pygame_display.QUIT)
    assert gui.handle_event(event) is False


def test_dealer_cards_reveal_after_round(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S")
    )
    session.place_bet(1_000)
    assert gui.dealer_revealed is False
    session.stand()
    assert gui.dealer_revealed is True
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
uv run pytest tests/test_lucky9_gui.py -q
```

Expected: FAIL because `gui.py` is fully commented out.

- [ ] **Step 3: Add GUI colors**

Append to `colors.py`:

```python
TABLE_GREEN = (18, 82, 56)
CARD_FACE = (250, 250, 245)
CARD_BACK = (30, 60, 140)
GOLD = (230, 190, 60)
```

- [ ] **Step 4: Replace `gui.py`**

```python
# ruff: noqa: E402
from __future__ import annotations

import os

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

import pygame

from python_game_suite.common.game_template import Game
from python_game_suite.lucky9.colors import (
    BLACK,
    CARD_BACK,
    CARD_FACE,
    GOLD,
    GRAY,
    RED,
    TABLE_GREEN,
    WHITE,
)
from python_game_suite.lucky9.gui_engine import (
    BET_OPTIONS,
    Lucky9Session,
    Phase,
)

WIDTH = 960
HEIGHT = 600
FPS = 60
CARD_W = 70
CARD_H = 100
CARD_GAP = 12
SUIT_LABELS = {
    chr(9830): ("D", RED),
    chr(9829): ("H", RED),
    chr(9824): ("S", BLACK),
    chr(9827): ("C", BLACK),
    "D": ("D", RED),
    "H": ("H", RED),
    "S": ("S", BLACK),
    "C": ("C", BLACK),
}


class Lucky9Gui(Game):
    def __init__(self, session: Lucky9Session | None = None):
        pygame.font.init()
        self.session = session or Lucky9Session()
        self.buttons: dict[str, pygame.Rect] = {}
        self.font_title = pygame.font.Font(None, 52)
        self.font = pygame.font.Font(None, 30)
        self.font_small = pygame.font.Font(None, 22)

    @staticmethod
    def get_name():
        return "Lucky9 (GUI)"

    @property
    def dealer_revealed(self) -> bool:
        return self.session.phase in (
            Phase.ROUND_OVER,
            Phase.GAME_OVER,
        )

    def run(self) -> None:
        pygame.init()
        pygame.display.set_caption("Lucky 9")
        screen = pygame.display.set_mode((WIDTH, HEIGHT))
        clock = pygame.time.Clock()
        running = True
        while running:
            for event in pygame.event.get():
                running = self.handle_event(event)
                if not running:
                    break
            self.render(screen)
            pygame.display.flip()
            clock.tick(FPS)
        pygame.quit()

    def handle_event(self, event) -> bool:
        if event.type == pygame.QUIT:
            return False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_q:
                return False
            if self.session.phase is Phase.BETTING and event.key in (
                pygame.K_1,
                pygame.K_2,
                pygame.K_3,
            ):
                index = event.key - pygame.K_1
                self.session.place_bet(BET_OPTIONS[index])
            elif self.session.phase is Phase.PLAYER_TURN:
                if event.key == pygame.K_h:
                    self.session.hit()
                elif event.key == pygame.K_g:
                    self.session.stand()
            elif (
                self.session.phase is Phase.ROUND_OVER
                and event.key == pygame.K_n
            ):
                self.session.next_round()
            elif (
                self.session.phase is Phase.GAME_OVER
                and event.key == pygame.K_r
            ):
                self.session.restart()

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for action, rect in self.buttons.items():
                if rect.collidepoint(event.pos):
                    return self._run_action(action)

        return True

    def _run_action(self, action: str) -> bool:
        if action == "quit":
            return False
        if action.startswith("bet:"):
            self.session.place_bet(int(action.split(":", 1)[1]))
        elif action == "hit":
            self.session.hit()
        elif action == "stand":
            self.session.stand()
        elif action == "next":
            self.session.next_round()
        elif action == "restart":
            self.session.restart()
        return True

    def render(self, surface) -> None:
        surface.fill(TABLE_GREEN)
        self.buttons = {}

        title = self.font_title.render("Lucky 9", True, GOLD)
        surface.blit(title, (WIDTH // 2 - title.get_width() // 2, 12))

        stats = [
            f"Level: {self.session.level}",
            f"You: {self.session.player.money:,}",
            f"Dealer: {self.session.dealer.name} "
            f"({self.session.dealer.money:,})",
            f"Bet: {self.session.bet:,}",
        ]
        x = 24
        for text in stats:
            rendered = self.font_small.render(text, True, WHITE)
            surface.blit(rendered, (x, 72))
            x += rendered.get_width() + 28

        revealed = self.dealer_revealed
        dealer_value = (
            self.session.dealer.getHandValue() if revealed else "??"
        )
        self._draw_hand(
            surface,
            self.session.dealer.hand,
            (WIDTH // 2 - CARD_W, 130),
            f"Dealer: {dealer_value}",
            face_up=revealed,
            hidden_index=1,
        )
        self._draw_hand(
            surface,
            self.session.player.hand,
            (WIDTH // 2 - CARD_W, 330),
            f"You: {self.session.player.getHandValue()}",
            face_up=True,
        )

        message = self.font.render(self.session.message, True, GOLD)
        surface.blit(
            message,
            (WIDTH // 2 - message.get_width() // 2, 470),
        )
        self._draw_buttons(surface)

    def _draw_hand(
        self,
        surface,
        hand,
        origin,
        label,
        face_up=True,
        hidden_index=None,
    ) -> None:
        text = self.font_small.render(label, True, WHITE)
        surface.blit(text, (origin[0], origin[1] - 26))
        if not hand:
            empty = self.font_small.render("No cards", True, GRAY)
            surface.blit(empty, (origin[0], origin[1] + 30))
            return
        for index, card in enumerate(hand):
            shown = face_up or index != hidden_index
            self._draw_card(
                surface,
                card,
                (origin[0] + index * (CARD_W + CARD_GAP), origin[1]),
                shown,
            )

    def _draw_card(self, surface, card, pos, face_up) -> None:
        rect = pygame.Rect(pos, (CARD_W, CARD_H))
        if not face_up:
            pygame.draw.rect(surface, CARD_BACK, rect, border_radius=8)
            pygame.draw.rect(surface, WHITE, rect, 2, border_radius=8)
            inner = rect.inflate(-20, -20)
            pygame.draw.rect(surface, WHITE, inner, 1, border_radius=4)
            label = self.font_small.render("L9", True, WHITE)
            surface.blit(
                label,
                (
                    rect.centerx - label.get_width() // 2,
                    rect.centery - label.get_height() // 2,
                ),
            )
            return

        pygame.draw.rect(surface, CARD_FACE, rect, border_radius=8)
        pygame.draw.rect(surface, BLACK, rect, 2, border_radius=8)
        rank, suit = card
        label, color = SUIT_LABELS.get(suit, ("?", BLACK))
        rank_text = self.font.render(str(rank), True, color)
        suit_text = self.font.render(label, True, color)
        surface.blit(rank_text, (pos[0] + 8, pos[1] + 8))
        surface.blit(suit_text, (pos[0] + 8, pos[1] + 44))

    def _draw_buttons(self, surface) -> None:
        x = 24
        for amount in BET_OPTIONS:
            action = f"bet:{amount}"
            rect = pygame.Rect(x, 520, 140, 46)
            enabled = (
                self.session.phase is Phase.BETTING
                and amount <= self.session.player.money
            )
            self._draw_button(
                surface, rect, f"{amount:,}", enabled, action
            )
            x += 154

        actions = []
        if self.session.phase is Phase.PLAYER_TURN:
            actions = [("H Hit", "hit"), ("G Stand", "stand")]
        elif self.session.phase is Phase.ROUND_OVER:
            actions = [("N Next", "next")]
        elif self.session.phase is Phase.GAME_OVER:
            actions = [("R Restart", "restart")]
        actions.append(("Q Quit", "quit"))

        x = 520
        for label, action in actions:
            rect = pygame.Rect(x, 520, 130, 46)
            self._draw_button(surface, rect, label, True, action)
            x += 144

    def _draw_button(
        self, surface, rect, label, enabled, action
    ) -> None:
        color = GOLD if enabled else GRAY
        pygame.draw.rect(surface, color, rect, border_radius=8)
        pygame.draw.rect(surface, BLACK, rect, 2, border_radius=8)
        text = self.font_small.render(label, True, BLACK)
        surface.blit(
            text,
            (
                rect.centerx - text.get_width() // 2,
                rect.centery - text.get_height() // 2,
            ),
        )
        self.buttons[action] = rect
```

- [ ] **Step 5: Run the GUI tests**

Run:

```bash
uv run pytest tests/test_lucky9_gui.py -q
```

Expected: all GUI tests pass.

---

## Task 6: Main Menu Hardening

**Files:**
- Modify: `src/python_game_suite/main.py`
- Create: `tests/test_main.py`

- [ ] **Step 1: Write the failing main tests**

Create `tests/test_main.py`:

```python
import builtins

from python_game_suite import main


def test_discover_games_finds_expected_games():
    games = main.discover_games()
    assert {
        "Hangman",
        "Lucky9 (GUI)",
        "Lucky9 (Terminal)",
        "Mastermind",
        "Number Guessing",
        "Rock, Paper, Scissors",
    }.issubset(games)


def test_main_lists_games_sorted_and_exits(monkeypatch, capsys):
    games = main.discover_games()
    exit_choice = str(len(games) + 1)
    inputs = iter([exit_choice])
    monkeypatch.setattr(builtins, "input", lambda *_: next(inputs))

    main.main()

    output = capsys.readouterr().out
    assert "Welcome to the Python Game Suite" in output
    assert "Thanks for playing" in output
    positions = [output.index(name) for name in sorted(games)]
    assert positions == sorted(positions)


def test_discover_games_continues_after_import_error(monkeypatch):
    real_import = main.importlib.import_module

    def fake_import(name):
        if name.endswith("hangman.hangman"):
            raise RuntimeError("boom")
        return real_import(name)

    monkeypatch.setattr(main.importlib, "import_module", fake_import)
    games = main.discover_games()
    assert "Hangman" not in games
    assert "Mastermind" in games


def test_main_rejects_invalid_choice_then_exits(monkeypatch, capsys):
    games = main.discover_games()
    exit_choice = str(len(games) + 1)
    inputs = iter(["abc", exit_choice])
    monkeypatch.setattr(builtins, "input", lambda *_: next(inputs))

    main.main()

    output = capsys.readouterr().out
    assert "Invalid input" in output
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
uv run pytest tests/test_main.py -q
```

Expected: FAIL because the menu is not sorted and the new names are missing.

- [ ] **Step 3: Update `main.py`**

Change the discovery exception handler:

```python
        except Exception as e:
            print(f"Warning: Could not import module {module_name}: {e}")
```

Change the menu ordering:

```python
    game_map = sorted(available_games)
```

- [ ] **Step 4: Run the main tests**

Run:

```bash
uv run pytest tests/test_main.py -q
```

Expected: all main tests pass.

## Task 7: Classic Game Tests

**Files:**
- Create: `tests/test_rock_paper_scissors.py`
- Create: `tests/test_number_guessing.py`
- Create: `tests/test_hangman.py`
- Create: `tests/test_mastermind.py`

- [ ] **Step 1: Write the Rock, Paper, Scissors tests**

Create `tests/test_rock_paper_scissors.py`:

```python
import builtins

from python_game_suite import rock_paper_scissors
from python_game_suite.rock_paper_scissors.game import (
    RockPaperScissorsGame,
)


def feed(monkeypatch, values):
    iterator = iter(values)
    monkeypatch.setattr(builtins, "input", lambda *_: next(iterator))


def test_get_player_move_validates_and_maps(monkeypatch):
    game = RockPaperScissorsGame()
    feed(monkeypatch, ["x", "r"])
    assert game._get_player_move() == "rock"


def test_get_player_move_quit(monkeypatch):
    game = RockPaperScissorsGame()
    feed(monkeypatch, ["q"])
    assert game._get_player_move() is None


def test_play_round_tie_then_win(monkeypatch, capsys):
    game = RockPaperScissorsGame()
    monkeypatch.setattr(
        rock_paper_scissors.game.random, "choice", lambda _: "r"
    )
    feed(monkeypatch, ["r", "p", "p", "p"])
    game._play_round()
    output = capsys.readouterr().out
    assert "It's a Tie!" in output
    assert "You won the match" in output


def test_play_round_loss(monkeypatch, capsys):
    game = RockPaperScissorsGame()
    monkeypatch.setattr(
        rock_paper_scissors.game.random, "choice", lambda _: "r"
    )
    feed(monkeypatch, ["s", "s", "s"])
    game._play_round()
    assert "The Computer won the match" in capsys.readouterr().out


def test_play_round_quit_mid_game(monkeypatch, capsys):
    game = RockPaperScissorsGame()
    feed(monkeypatch, ["q"])
    game._play_round()
    assert "Round 1" in capsys.readouterr().out


def test_play_again_validation(monkeypatch):
    game = RockPaperScissorsGame()
    feed(monkeypatch, ["x", "y"])
    assert game._play_again() is True
    feed(monkeypatch, ["n"])
    assert game._play_again() is False


def test_game_name():
    assert RockPaperScissorsGame.get_name() == "Rock, Paper, Scissors"
```

- [ ] **Step 2: Write the Number Guessing tests**

Create `tests/test_number_guessing.py`:

```python
import builtins

from python_game_suite import number_guessing
from python_game_suite.number_guessing.game import NumberGuessingGame


def feed(monkeypatch, values):
    iterator = iter(values)
    monkeypatch.setattr(builtins, "input", lambda *_: next(iterator))


def test_play_round_hints_and_win(monkeypatch, capsys):
    game = NumberGuessingGame()
    monkeypatch.setattr(number_guessing.game.random, "randint", lambda a, b: 50)
    feed(monkeypatch, ["25", "75", "50"])
    game._play_round()
    output = capsys.readouterr().out
    assert "Too low!" in output
    assert "Too high!" in output
    assert "You got it!" in output


def test_play_round_invalid_then_quit(monkeypatch, capsys):
    game = NumberGuessingGame()
    monkeypatch.setattr(number_guessing.game.random, "randint", lambda a, b: 50)
    feed(monkeypatch, ["abc", "q"])
    game._play_round()
    output = capsys.readouterr().out
    assert "Invalid input" in output
    assert "The number was 50" in output


def test_play_again_validation(monkeypatch):
    game = NumberGuessingGame()
    feed(monkeypatch, ["x", "y"])
    assert game._play_again() is True
    feed(monkeypatch, ["n"])
    assert game._play_again() is False


def test_game_name():
    assert NumberGuessingGame.get_name() == "Number Guessing"
```

- [ ] **Step 3: Write the Hangman tests**

Create `tests/test_hangman.py`:

```python
import builtins

import pytest

from python_game_suite.hangman import hangman
from python_game_suite.hangman.hangman import HangmanGame
from python_game_suite.hangman.words import getWord


def feed(monkeypatch, values):
    iterator = iter(values)
    monkeypatch.setattr(builtins, "input", lambda *_: next(iterator))


def test_get_word_by_length():
    word = getWord(3)
    assert len(word) == 3


def test_get_word_missing_length():
    with pytest.raises(ValueError):
        getWord(12)


def test_word_length_prompt_validation(monkeypatch):
    game = HangmanGame()
    monkeypatch.setattr(hangman, "getWord", lambda length: "abc")
    feed(monkeypatch, ["abc", "0", "3"])
    assert game._get_word_length_from_user() == 3


def test_play_round_win(monkeypatch, capsys):
    game = HangmanGame()
    monkeypatch.setattr(hangman, "getWord", lambda length: "abc")
    feed(monkeypatch, ["3", "A", "B", "C"])
    game._play_round()
    assert "Congratulations!" in capsys.readouterr().out


def test_play_round_loss(monkeypatch, capsys):
    game = HangmanGame()
    monkeypatch.setattr(hangman, "getWord", lambda length: "abc")
    feed(monkeypatch, ["3", "D", "E", "F", "G", "H", "I"])
    game._play_round()
    assert "You died" in capsys.readouterr().out


def test_play_again_validation(monkeypatch):
    game = HangmanGame()
    feed(monkeypatch, ["x", "y"])
    assert game._play_again() is True
    feed(monkeypatch, ["n"])
    assert game._play_again() is False


def test_display_hangman_stages():
    game = HangmanGame()
    for tries in range(7):
        game._display_hangman(tries)


def test_game_name():
    assert HangmanGame.get_name() == "Hangman"
```

- [ ] **Step 4: Write the Mastermind tests**

Create `tests/test_mastermind.py`:

```python
import builtins

from python_game_suite import mastermind
from python_game_suite.mastermind.game import MastermindGame


def feed(monkeypatch, values):
    iterator = iter(values)
    monkeypatch.setattr(builtins, "input", lambda *_: next(iterator))


def test_generate_code_is_unique_and_numeric():
    game = MastermindGame()
    code = game._generate_code()
    assert len(code) == 4
    assert code.isdigit()
    assert len(set(code)) == 4


def test_get_guess_validation(monkeypatch):
    game = MastermindGame()
    feed(monkeypatch, ["123", "abcd", "1123", "1234"])
    assert game._get_guess() == "1234"


def test_evaluate_guess(monkeypatch):
    game = MastermindGame()
    monkeypatch.setattr(mastermind.game.random, "shuffle", lambda _: None)
    assert game._evaluate_guess("1234", "1243") == "OOXX"


def test_play_round_win(monkeypatch, capsys):
    game = MastermindGame()
    feed(monkeypatch, ["1234"])
    game._play_round("1234")
    assert "Congratulations!" in capsys.readouterr().out


def test_play_round_attempt_limit(monkeypatch, capsys):
    game = MastermindGame()
    feed(monkeypatch, ["5678"] * 10)
    game._play_round("1234")
    output = capsys.readouterr().out
    assert "used all 10 attempts" in output
    assert "The secret code was 1234" in output


def test_play_again_validation(monkeypatch):
    game = MastermindGame()
    feed(monkeypatch, ["x", "n"])
    assert game._play_again() is False


def test_game_name():
    assert MastermindGame.get_name() == "Mastermind"
```

- [ ] **Step 5: Run all classic game tests**

Run:

```bash
uv run pytest tests/test_rock_paper_scissors.py tests/test_number_guessing.py tests/test_hangman.py tests/test_mastermind.py -q
```

Expected: all tests pass.

---

## Task 8: Documentation, Screenshot, and Final Verification

**Files:**
- Replace: `README.md`
- Create: `CONTEXT.md`
- Create: `scripts/render_screenshot.py`
- Generate: `docs/screenshot.png`

- [ ] **Step 1: Create the screenshot script**

Create `scripts/render_screenshot.py`:

```python
# ruff: noqa: E402
import os
from pathlib import Path

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")
os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

import pygame

from python_game_suite.lucky9.gui import Lucky9Gui
from python_game_suite.lucky9.gui_engine import Lucky9Session


def main() -> None:
    deck = [
        ("A", chr(9829)),
        ("9", chr(9824)),
        ("5", chr(9830)),
        ("2", chr(9827)),
    ] * 10
    pygame.init()
    session = Lucky9Session(deck_factory=lambda: deck)
    session.place_bet(1_000)
    session.hit()
    gui = Lucky9Gui(session)
    surface = pygame.Surface((960, 600))
    gui.render(surface)
    output = Path("docs/screenshot.png")
    output.parent.mkdir(parents=True, exist_ok=True)
    pygame.image.save(surface, str(output))
    pygame.quit()
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Generate the screenshot**

Run:

```bash
uv run python scripts/render_screenshot.py
```

Expected: `Wrote docs/screenshot.png`.

- [ ] **Step 3: Replace `README.md`**

```markdown
# Python Game Suite

[![CI](https://github.com/Onehand-Coding/python-game-suite/actions/workflows/ci.yml/badge.svg)](https://github.com/Onehand-Coding/python-game-suite/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)

A collection of classic terminal and GUI games built with Python. Games are
discovered automatically at runtime, so adding a new one does not require
editing the launcher.

![Lucky9 GUI](docs/screenshot.png)

## Games

| Game | Mode | Description |
| --- | --- | --- |
| Hangman | Terminal | Word guessing with ASCII art |
| Lucky9 | Terminal | Card game with saves, levels, and debt |
| Lucky9 | GUI | Playable pygame card game with mouse and keyboard |
| Mastermind | Terminal | Code-breaking logic puzzle |
| Number Guessing | Terminal | Guess the computer's number with hints |
| Rock, Paper, Scissors | Terminal | Best-of-five hand game |

## Quick Start

Requirements: Python 3.10+ and [uv](https://github.com/astral-sh/uv).

```bash
git clone https://github.com/Onehand-Coding/python-game-suite.git
cd python-game-suite
uv sync --extra dev
uv run run-games
```

## Controls

### Lucky9 GUI

| Input | Action |
| --- | --- |
| `1`, `2`, `3` or chip click | Bet 1,000, 2,000, or 5,000 |
| `H` or Hit | Draw one card |
| `G` or Stand | Let the dealer draw and reveal |
| `N` or Next | Start the next round |
| `R` or Restart | Restart after game over |
| `Q` | Quit |

The dealer draws while under 7. Hearts and diamonds are red; spades and clubs
are black. Cards are drawn with pygame primitives, so there are no external art
assets.

### Lucky9 Terminal

The terminal game accepts bets, `H`/`G` moves, `SAVE`, `DELETE`, `PLAYERS`,
`CLEAR`, and `Q`/`EXIT`. Saved games go to the data directory.

### Other Games

Each terminal game prompts for its own input and supports a play-again loop.

## Data Directory

Lucky9 save data lives outside the package:

- Default: `~/.local/share/python-game-suite`
- Override: `PYTHON_GAME_SUITE_DATA_DIR=/path/to/data`

No data or asset directories are created in `src` at import time.

## Architecture

```
src/python_game_suite/
  main.py                         discovery and menu
  common/game_template.py         Game abstract base class
  hangman/                        terminal game
  mastermind/                     terminal game
  number_guessing/                terminal game
  rock_paper_scissors/            terminal game
  lucky9/
    terminal_engine.py            shared rules, players, dealers, persistence
    terminal.py                   terminal prompts and commands
    gui_engine.py                 pure Lucky9Session state machine
    gui.py                        pygame rendering and events
    config.py                     user data directory
    colors.py                     shared colors
```

The GUI session has no pygame imports. The view renders the session and
translates key and mouse events. Terminal and GUI Lucky9 share the same engine.

## Development

```bash
uv sync --extra dev
uv run ruff check .
uv run ruff format --check .
uv run pytest
```

Tests use `SDL_VIDEODRIVER=dummy`, so they do not open a window. CI runs the same
commands on push and pull request.

## Adding a Game

1. Create a package under `src/python_game_suite/`.
2. Subclass `Game` from `python_game_suite.common.game_template`.
3. Implement `get_name()` and `run()`.
4. The launcher discovers the class automatically.

```python
from python_game_suite.common.game_template import Game


class MyGame(Game):
    @staticmethod
    def get_name() -> str:
        return "My Game"

    def run(self) -> None:
        print("Hello from My Game")
```

Add tests under `tests/` and run `uv run pytest`.

## License

MIT. See `LICENSE`.
```

- [ ] **Step 4: Create `CONTEXT.md`**

```markdown
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

## Known Limitations

- The GUI has no animations, sound, or save/load.
- The terminal game is Tagalog-first and intentionally informal.
- Lucky9 levels are capped at 5.
```

- [ ] **Step 5: Run the full verification**

Run:

```bash
uv sync --extra dev
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv run python scripts/render_screenshot.py
uv build
python3 -m zipfile -l dist/*.whl | grep words.txt
printf "7\n" | uv run run-games
```

Expected:

- Ruff and format checks pass.
- All tests pass.
- The screenshot is written.
- The wheel contains `python_game_suite/hangman/words.txt`.
- The menu lists six games and exits cleanly.

- [ ] **Step 6: Headless GUI smoke test**

Run:

```bash
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy uv run python -c "
from python_game_suite.lucky9.gui import Lucky9Gui
from python_game_suite.lucky9.gui_engine import Lucky9Session
gui = Lucky9Gui(Lucky9Session())
print(gui.get_name())
"
```

Expected: `Lucky9 (GUI)`.

- [ ] **Step 7: Report status**

Summarize:

- Files changed.
- Test and lint results.
- Any unverified item, with the exact command needed to verify it.

Do not commit or push unless the user explicitly asks.

---

## Implementation Notes

Deviations made during execution:

- The dealer draw is capped at three cards. Without the cap, the modulo-10 hand
  value could leave the dealer drawing seven or more cards and overflow the
  window.
- Rock, Paper, Scissors `_play_again` now validates input like the other games
  instead of treating any non-`y` input as no.
- `Lucky9` initializes `isLoaded` and `Player.getHandValue` is annotated as
  `int | str` to reflect the hidden-value path.
- `Lucky9Session` tests include the dealer three-card cap.
- The generated screenshot was inspected and regenerated after the cap fix.

Post-review additions:

- Added a `clearData` sentinel test that proves unrelated files survive.
- Added a data-directory override test that proves saves land under the supplied
  path.
- Added GUI hit-key and hit-button tests plus wrong-phase and second-hit session
  tests.
- Added terminal debt message assertions for paid, refused, and penalty paths.
- Clamped the displayed dealer balance at zero during an overdrawn round.
- CI now builds a wheel and checks that `hangman/words.txt` is packaged.


