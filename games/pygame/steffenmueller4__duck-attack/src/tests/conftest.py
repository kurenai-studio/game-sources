import os

# Run Pygame headless so tests work without a display (e.g. in CI).
os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pytest  # noqa: E402

from duck_attack import settings  # noqa: E402


@pytest.fixture(autouse=True)
def isolated_highscores(tmp_path, monkeypatch):
    """Never touch the player's real high-score file from tests."""
    path = tmp_path / "highscores.json"
    monkeypatch.setattr(settings, "HIGHSCORES_FILE", path)
    return path


@pytest.fixture(autouse=True)
def isolated_player_name(tmp_path, monkeypatch):
    """Never touch the player's real remembered name from tests."""
    path = tmp_path / "player.txt"
    monkeypatch.setattr(settings, "PLAYER_NAME_FILE", path)
    return path
