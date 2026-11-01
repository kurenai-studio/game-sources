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
