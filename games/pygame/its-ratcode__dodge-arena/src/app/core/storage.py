"""The save file: one JSON document that holds every saved section.

Layout::

    {
      "version": 1,
      "progress": { ... }      <- app.progression.profile.Profile
    }

Each section is a plain dict owned by one part of the game. A missing or
corrupt file is not an error: the game simply starts fresh. Writes go to a
temporary file first and then replace the real one, so a crash mid-write can
never leave a half-written save behind.
"""

import json
import os
import sys
from pathlib import Path

from app import config
from app.meta import APP_NAME

SAVE_VERSION = 1


def user_data_dir() -> Path:
    """The per-user folder where this OS expects apps to keep their data.

    The folder is named after ``APP_NAME``, so renaming the game moves it too.
    """
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA") or Path.home() / "AppData" / "Roaming")
    elif sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support"
    else:                                                   # Linux and other Unix: XDG spec
        base = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share")
    return base / APP_NAME


def default_save_path() -> Path:
    return user_data_dir() / config.SAVE_FILENAME


class SaveFile:
    """Reads the save file once, hands out sections and writes them back."""

    def __init__(self, path: str | Path | None = None) -> None:
        self.path = Path(path) if path else default_save_path()
        self.sections: dict[str, dict] = {}
        self.load()

    def load(self) -> None:
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
        except (OSError, ValueError):                   # missing or not valid JSON: start fresh
            return
        if isinstance(data, dict):
            self.sections = {name: value for name, value in data.items() if isinstance(value, dict)}

    def section(self, name: str) -> dict:
        """The saved dict for ``name`` (empty if there is none). Callers validate it."""
        return self.sections.get(name, {})

    def write(self, name: str, values: dict) -> bool:
        """Replace one section and save the whole file. Returns False if it could not be written."""
        self.sections[name] = values
        document = {"version": SAVE_VERSION, **self.sections}
        temp = self.path.with_suffix(".tmp")
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            temp.write_text(json.dumps(document, indent=2), encoding="utf-8")
            os.replace(temp, self.path)                 # atomic swap on the same drive
        except OSError:
            return False
        return True
