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
    monkeypatch.setattr(rock_paper_scissors.game.random, "choice", lambda _: "r")
    feed(monkeypatch, ["r", "p", "p", "p"])
    game._play_round()
    output = capsys.readouterr().out
    assert "It's a Tie!" in output
    assert "You won the match" in output


def test_play_round_loss(monkeypatch, capsys):
    game = RockPaperScissorsGame()
    monkeypatch.setattr(rock_paper_scissors.game.random, "choice", lambda _: "r")
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
