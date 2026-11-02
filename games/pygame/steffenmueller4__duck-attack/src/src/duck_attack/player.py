"""The player's name, remembered between rounds and sessions."""

from pathlib import Path


def load_player_name(path: Path) -> str:
    """Return the last used player name, or an empty string if there is none."""
    try:
        return path.read_text().strip()
    except (OSError, UnicodeDecodeError):
        return ""


def save_player_name(path: Path, name: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(name)
