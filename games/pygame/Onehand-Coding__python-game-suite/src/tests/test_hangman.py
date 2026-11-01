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
