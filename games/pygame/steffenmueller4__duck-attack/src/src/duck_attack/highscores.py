"""High-score list, persisted as JSON."""

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from duck_attack import settings


@dataclass(frozen=True)
class HighScore:
    score: int
    timestamp: datetime  # when the round started; identifies the round
    name: str = ""  # player name; empty for entries saved before names existed


class HighScoreList:
    """The best rounds, highest score first (ties: earlier round first)."""

    def __init__(self, path: Path, max_entries: int = settings.MAX_HIGHSCORES) -> None:
        self.path = path
        self.max_entries = max_entries
        self.entries: list[HighScore] = self._load()

    def _load(self) -> list[HighScore]:
        try:
            data = json.loads(self.path.read_text())
            return [
                HighScore(
                    int(item["score"]),
                    datetime.fromisoformat(item["timestamp"]),
                    str(item.get("name", "")),
                )
                for item in data
            ]
        except FileNotFoundError:
            return []
        except (ValueError, KeyError, TypeError):
            # A corrupt file shouldn't stop the game; start a fresh list.
            return []

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        data = [
            {"score": e.score, "timestamp": e.timestamp.isoformat(), "name": e.name}
            for e in self.entries
        ]
        self.path.write_text(json.dumps(data, indent=2))

    def add(self, entry: HighScore) -> int | None:
        """Add ``entry`` and save. Returns its index in the list, or None if it didn't make it."""
        self.entries.append(entry)
        self.entries.sort(key=lambda e: (-e.score, e.timestamp))
        del self.entries[self.max_entries :]
        self.save()
        return self.entries.index(entry) if entry in self.entries else None
