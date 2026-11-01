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
