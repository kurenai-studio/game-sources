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
