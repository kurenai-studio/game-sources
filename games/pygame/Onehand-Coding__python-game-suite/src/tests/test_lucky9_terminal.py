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


def test_collect_debt_paid(tmp_path, monkeypatch, capsys):
    game = make_game(tmp_path)
    game.player.money = 50_000
    game.player.debt = 10_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: True)
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    feed(monkeypatch, [""])
    terminal.collectPlayerDebt()
    assert game.player.debt == 0
    assert game.player.money == 40_000
    assert "Ayan bayad na utang mo." in capsys.readouterr().out


def test_collect_debt_refused(tmp_path, monkeypatch, capsys):
    game = make_game(tmp_path)
    game.player.money = 50_000
    game.player.debt = 10_000
    monkeypatch.setattr(terminal, "yesOrNo", lambda: False)
    monkeypatch.setattr(terminal.time, "sleep", lambda *_: None)
    terminal.collectPlayerDebt()
    assert game.player.debt == 10_000
    assert game.player.timesRefusedToPay == 1
    assert "pagka kuripot naman?" in capsys.readouterr().out


def test_collect_debt_penalty(tmp_path, monkeypatch, capsys):
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
    assert "babawasan ng doble ang pera mo." in capsys.readouterr().out


def test_terminal_game_name():
    assert terminal.TerminalLucky9.get_name() == "Lucky9 (Terminal)"
