from __future__ import annotations

import os
from pathlib import Path


def get_data_dir() -> Path:
    override = os.getenv("PYTHON_GAME_SUITE_DATA_DIR")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".local" / "share" / "python-game-suite"


DATA_DIR = get_data_dir()
