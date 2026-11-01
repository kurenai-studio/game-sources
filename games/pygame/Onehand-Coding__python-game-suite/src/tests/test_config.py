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
